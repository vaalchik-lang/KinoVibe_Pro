import os
import requests
import json

class SmartAgent:
    def __init__(self):
        # Читаем строку ключей и превращаем в список
        raw_keys = os.getenv("GEMINI_API_KEYS", "")
        self.key_pool = [k.strip() for k in raw_keys.split(",") if k.strip()]
        self.current_key_idx = 0

    def ask_gemini(self, prompt):
        while self.current_key_idx < len(self.key_pool):
            key = self.key_pool[self.current_key_idx]
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
            
            try:
                print(f"AGENT: Пробую ключ №{self.current_key_idx}...")
                response = requests.post(url, json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"temperature": 0.1}
                }, timeout=30)
                
                if response.status_code == 200:
                    return response.json()['candidates'][0]['content']['parts'][0]['text']
                elif response.status_code in [429, 403]: # Лимиты или невалидный ключ
                    print(f"AGENT: Ключ №{self.current_key_idx} недоступен. Ротация...")
                    self.current_key_idx += 1
                else:
                    print(f"AGENT: Системная ошибка {response.status_code}")
                    self.current_key_idx += 1
            except Exception as e:
                print(f"AGENT: Ошибка связи: {e}")
                self.current_key_idx += 1
        return None

def main():
    if not os.path.exists("build_error.log"):
        return

    agent = SmartAgent()
    with open("build_error.log", "r") as f:
        log_data = f.read()[-3000:]

    with open("client/pubspec.yaml", "r") as f:
        current_pub = f.read()

    prompt = f"ERROR LOG:\n{log_data}\n\nCURRENT PUBSPEC:\n{current_pub}\n\nFix pubspec.yaml to resolve conflict. Output ONLY clean code."
    
    fix = agent.ask_gemini(prompt)
    if fix and "name:" in fix:
        with open("client/pubspec.yaml", "w") as f:
            f.write(fix)
        print("AGENT: Фикс успешно применен.")
    else:
        print("AGENT: Не удалось получить решение от LLM.")

if __name__ == "__main__":
    main()
