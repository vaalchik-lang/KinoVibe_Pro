import os
import sys
import json
import mysql.connector
import requests
import subprocess
import re
import time
from datetime import datetime

# Добавляем путь для импорта твоего KeyPool
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from core.key_pool import get_pool

class AutonomousArchitect:
    def __init__(self):
        # 1. Инициализация БД
        try:
            self.db = mysql.connector.connect(
                host="localhost",
                user="root",
                password="",
                database="agent_core"
            )
            self.cursor = self.db.cursor(dictionary=True)
            print(">> [SYSTEM]: MariaDB подключена.")
        except Exception as e:
            print(f">> [CRITICAL]: Ошибка БД: {e}")
            sys.exit(1)

        # 2. Инициализация ресурсов
        self.pool = get_pool()
        self.serper_key = os.getenv("SERPER_API_KEY")
        self.base_scan_path = "/storage/emulated/0/Documents/ПРОМТЫ/"

    def _ask_gemini(self, system_instruction, user_data):
        """Запрос к Gemini через KeyPool с автоматической ротацией"""
        max_retries = 5
        for attempt in range(max_retries):
            try:
                entry, provider = self.pool.get_best(prefer="gemini")
                url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={entry.value}"
                
                payload = {
                    "contents": [{
                        "parts": [{"text": f"{system_instruction}\n\nDATA:\n{user_data[:10000]}"}]
                    }]
                }
                
                t0 = time.monotonic()
                r = requests.post(url, json=payload, timeout=30)
                latency = time.monotonic() - t0
                
                if r.status_code == 200:
                    res_json = r.json()
                    self.pool.report(entry, code=200, tokens=0, latency=latency, model="gemini-2.5-flash")
                    return res_json['candidates'][0]['content']['parts'][0]['text']
                else:
                    print(f">> [WARN]: Ошибка API {r.status_code}. Ротация ключа...")
                    self.pool.report(entry, code=r.status_code, latency=latency)
                    continue # Пробуем следующий ключ из пула
                    
            except Exception as e:
                print(f">> [ERROR]: Сбой в цикле запроса: {e}")
                time.sleep(1)
        return None

    def search_online(self, query):
        """Глобальный поиск через Serper API"""
        if not self.serper_key:
            return "Serper API key not found."
        
        print(f">> [SERPER]: Поиск: {query}")
        headers = {'X-API-KEY': self.serper_key, 'Content-Type': 'application/json'}
        try:
            r = requests.post("https://google.serper.dev/search", 
                             headers=headers, 
                             json={"q": query})
            return r.json().get('organic', [])[:3]
        except:
            return []

    def ingest_knowledge(self):
        """Первичное обучение: поглощение всех промптов в MySQL"""
        print(f">> [INGESTION]: Начинаю сканирование {self.base_scan_path}...")
        
        for root, dirs, files in os.walk(self.base_scan_path):
            # Пропускаем служебные директории
            if any(x in root for x in [".system", ".git", "node_modules"]):
                continue
                
            for file in files:
                if file.endswith(('.txt', '.md', '.py')):
                    f_path = os.path.join(root, file)
                    print(f"   - Обработка: {file}")
                    
                    try:
                        with open(f_path, 'r', errors='ignore') as f:
                            content = f.read()
                        
                        if len(content.strip()) < 20: continue

                        prompt = """Анализируй файл и выдели логику автоматизации. 
                        Верни ТОЛЬКО JSON: {"tag": "категория", "pattern_name": "название", "solution": "суть решения/код"}"""
                        
                        analysis = self._ask_gemini(prompt, content)
                        if analysis:
                            # Очистка JSON от маркдауна
                            clean_json = re.sub(r'```json\n?|\n?```', '', analysis).strip()
                            data = json.loads(clean_json)
                            
                            self.cursor.execute(
                                """INSERT IGNORE INTO global_knowledge 
                                (context_tag, pattern_name, solution_payload, source_url) 
                                VALUES (%s, %s, %s, %s)""",
                                (data.get('tag'), data.get('pattern_name'), data.get('solution'), f_path)
                            )
                            self.db.commit()
                    except Exception as e:
                        print(f"   ! Ошибка в {file}: {e}")

    def run_autonomous_fix(self, error_log):
        """Полный цикл: Ошибка -> База -> Поиск -> Фикс"""
        print(">> [AUTONOMOUS]: Запуск цикла исправления...")
        
        # 1. Проверка локальной базы
        self.cursor.execute("SELECT solution_payload FROM global_knowledge WHERE problem_signature LIKE %s", 
                           (f"%{error_log[:50]}%",))
        cached = self.cursor.fetchone()
        
        if cached:
            print(">> [MATCH]: Найдено готовое решение в MariaDB.")
            return cached['solution_payload']

        # 2. Внешний поиск
        web_data = self.search_online(f"fix error: {error_log[:100]}")
        
        # 3. Синтез
        instruction = "Используй логи логов и результаты поиска для создания фикса."
        fix = self._ask_gemini(instruction, f"LOG: {error_log}\nWEB: {web_data}")
        
        if fix:
            # Саморазвитие: записываем новый опыт
            self.cursor.execute(
                "INSERT INTO global_knowledge (context_tag, problem_signature, solution_payload) VALUES (%s, %s, %s)",
                ("auto-fix", error_log[:200], fix)
            )
            self.db.commit()
            print(">> [SUCCESS]: Решение усвоено и сохранено.")
            return fix
        
        return None

if __name__ == "__main__":
    agent = AutonomousArchitect()
    # Если запущен без аргументов — проводим индексацию базы
    if len(sys.argv) == 1:
        agent.ingest_knowledge()
    else:
        # Если переданы аргументы (лог ошибки) — чиним
        error_input = " ".join(sys.argv[1:])
        print(agent.run_autonomous_fix(error_input))
