import os
import requests
import json

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
    # Ищем лог в корне или в текущей папке
    log_path = "build_error.log"
    
    if not os.path.exists(log_path):
        print(f"AGENT: Лог {log_path} не найден. Работа в режиме диагностики без логов.")
        log_data = "No log file found. Check environment scaffold."
    else:
        with open(log_path, "r") as f:
            log_data = f.read()[-4000:]

    # Всегда создаем файл статуса в начале, чтобы избежать ошибок workflow
    with open("agent_status.env", "w") as f:
        f.write("CHANGES_DETECTED=false\n")

    pub_path = "client/pubspec.yaml"
    if not os.path.exists(pub_path):
        print("AGENT: pubspec.yaml не найден.")
        return

    agent = SmartAgent()
    with open(pub_path, "r") as f:
        current_pub = f.read()

    prompt = f"ERROR LOG:\n{log_data}\n\nCURRENT PUBSPEC:\n{current_pub}\n\nFix version conflicts. Output ONLY clean code."
    
    fix = agent.ask_gemini(prompt)
    
    if fix and "name:" in fix and fix.strip() != current_pub.strip():
        with open(pub_path, "w") as f:
            f.write(fix)
        with open("agent_status.env", "w") as f:
            f.write("CHANGES_DETECTED=true\n")
        print("AGENT: Решение применено.")

if __name__ == "__main__":
    main()
