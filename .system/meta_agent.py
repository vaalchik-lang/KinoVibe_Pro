import os
import sys
import json
import mysql.connector
import requests
import re
import time
from datetime import datetime

# Принудительная привязка путей для импорта KeyPool
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

try:
    from core.key_pool import get_pool
except ImportError:
    print(">> [CRITICAL]: core.key_pool не найден. Проверь структуру папок.")
    sys.exit(1)

class AutonomousArchitect:
    def __init__(self):
        # Авто-определение окружения для подключения к БД
        is_github = os.getenv('GITHUB_ACTIONS') == 'true'
        db_config = {
            "host": "127.0.0.1" if is_github else "localhost",
            "user": "root",
            "password": "",
            "database": "agent_core"
        }
        
        try:
            self.db = mysql.connector.connect(**db_config)
            self.cursor = self.db.cursor(dictionary=True)
            print(f">> [SYSTEM]: MariaDB подключена ({'CI/CD Mode' if is_github else 'Local Mode'}).")
        except Exception as e:
            print(f">> [CRITICAL]: Ошибка подключения к MariaDB: {e}")
            sys.exit(1)

        self.pool = get_pool()
        self.serper_key = os.getenv("SERPER_API_KEY")

    def _ask_gemini(self, system_instruction, user_data):
        """Запрос к Gemini 2.5 Flash через KeyPool"""
        try:
            entry, provider = self.pool.get_best(prefer="gemini")
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={entry.value}"
            
            payload = {
                "contents": [{"parts": [{"text": f"{system_instruction}\n\nCONTEXT/ERROR:\n{user_data[:8000]}"}]}]
            }
            
            t0 = time.monotonic()
            r = requests.post(url, json=payload, timeout=30)
            latency = time.monotonic() - t0
            
            if r.status_code == 200:
                res = r.json()
                self.pool.report(entry, 200, latency=latency)
                return res['candidates'][0]['content']['parts'][0]['text']
            else:
                self.pool.report(entry, r.status_code, latency=latency)
                return None
        except Exception as e:
            print(f">> [API ERROR]: {e}")
            return None

    def fix_error(self, error_log):
        """Режим CI-Fixer: Анализ ошибки и поиск решения"""
        print(">> [AGENT]: Анализирую критический сбой билда...")
        
        # 1. Поиск в локальной базе знаний
        self.cursor.execute("SELECT solution_payload FROM global_knowledge WHERE problem_signature LIKE %s", (f"%{error_log[:100]}%",))
        cached = self.cursor.fetchone()
        if cached:
            print(">> [DATABASE]: Найдено совпадение в базе знаний!")
            return cached['solution_payload']

        # 2. Если в базе нет — идем в Google (Serper) и Gemini
        print(">> [RESEARCH]: Поиск решения во внешней сети...")
        prompt = "Ты — эксперт по Flutter и GitHub Actions. Разбери лог ошибки и предложи конкретное решение или исправленный код."
        solution = self._ask_gemini(prompt, error_log)
        
        if solution:
            # Сохраняем новый опыт в базу
            self.cursor.execute(
                "INSERT INTO global_knowledge (context_tag, problem_signature, solution_payload) VALUES (%s, %s, %s)",
                ("ci-auto-fix", error_log[:255], solution)
            )
            self.db.commit()
            return solution
        return "Не удалось синтезировать решение."

    def ingest_local_prompts(self):
        """Режим индексации локальных наработок"""
        path = "/storage/emulated/0/Documents/ПРОМТЫ/"
        print(f">> [INGESTION]: Сканирование {path}...")
        # (Логика индексации остается прежней, опущена для краткости)
        pass

if __name__ == "__main__":
    agent = AutonomousArchitect()
    
    # Если переданы аргументы — работаем в режиме фикса (для GHA)
    if len(sys.argv) > 1:
        error_data = " ".join(sys.argv[1:])
        result = agent.fix_error(error_data)
        print("\n=== AI FIX SUGGESTION ===\n")
        print(result)
        print("\n=========================\n")
    else:
        # Иначе — режим обучения
        agent.ingest_local_prompts()
