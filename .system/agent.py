import os
import requests
import json
import subprocess

class SmartAgent:
    def __init__(self):
        raw_keys = os.getenv("GEMINI_API_KEYS", "")
        self.key_pool = [k.strip() for k in raw_keys.split(",") if k.strip()]
        self.current_key_idx = 0

    def ask_gemini(self, prompt):
        while self.current_key_idx < len(self.key_pool):
            key = self.key_pool[self.current_key_idx]
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
            try:
                print(f"AGENT: Запрос к Gemini 2.5 Flash (Ключ {self.current_key_idx})...")
                response = requests.post(url, json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"temperature": 0.1}
                }, timeout=30)
                if response.status_code == 200:
                    return response.json()['candidates'][0]['content']['parts'][0]['text']
                self.current_key_idx += 1
            except:
                self.current_key_idx += 1
        return None

def main():
    if not os.path.exists("build_error.log"):
        print("AGENT: Лог ошибки не найден.")
        return

    agent = SmartAgent()
    with open("build_error.log", "r") as f:
        log_data = f.read()[-4000:]

    with open("client/pubspec.yaml", "r") as f:
        current_pub = f.read()

    prompt = f"""
    PROJECT: KINOVIBE
    ROLE: Senior Flutter Engineer / Agent
    ERROR: {log_data}
    FILE: {current_pub}
    TASK: Проанализируй ошибку. Если это конфликт версий в pubspec.yaml, верни исправленный файл целиком. 
    Если причина в другом (Gradle, Java, SDK), напиши кратко 'NOT_A_PUBSPEC_ERROR'.
    ОТВЕТ: Только код или статус.
    """
    
    fix = agent.ask_gemini(prompt)
    
    if fix and "name:" in fix and fix.strip() != current_pub.strip():
        with open("client/pubspec.yaml", "w") as f:
            f.write(fix)
        print("AGENT: Обнаружено решение. Файл обновлен.")
        # Создаем флаг для GitHub Actions, что изменения ЕСТЬ
        with open("agent_status.env", "w") as f:
            f.write("CHANGES_DETECTED=true")
    else:
        print("AGENT: Изменений не требуется или ошибка вне pubspec.yaml.")
        with open("agent_status.env", "w") as f:
            f.write("CHANGES_DETECTED=false")

if __name__ == "__main__":
    main()
