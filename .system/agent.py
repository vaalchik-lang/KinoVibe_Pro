import os
import requests
import json
import re

class SmartAgent:
    def __init__(self):
        raw_keys = os.getenv("GEMINI_API_KEYS", "")
        self.key_pool = [k.strip() for k in raw_keys.split(",") if k.strip()]
        self.current_key_idx = 0

    def clean_code(self, text):
        # Удаляем Markdown блоки ```yaml или ``` и закрывающие теги
        cleaned = re.sub(r'```[a-zA-Z]*\n', '', text)
        cleaned = cleaned.replace('```', '')
        return cleaned.strip()

    def ask_gemini(self, prompt):
        while self.current_key_idx < len(self.key_pool):
            key = self.key_pool[self.current_key_idx]
            url = f"[https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=](https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=){key}"
            try:
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
    log_path = "build_error.log"
    with open("agent_status.env", "w") as f:
        f.write("CHANGES_DETECTED=false\n")

    if not os.path.exists(log_path):
        log_data = "Unknown error. Check syntax."
    else:
        with open(log_path, "r") as f:
            log_data = f.read()[-4000:]

    pub_path = "client/pubspec.yaml"
    with open(pub_path, "r") as f:
        current_pub = f.read()

    agent = SmartAgent()
    prompt = f"ERROR:\n{log_data}\n\nFILE:\n{current_pub}\n\nTask: Fix the file. Return ONLY the code. NO Markdown."
    
    raw_fix = agent.ask_gemini(prompt)
    if raw_fix:
        # ПРИМЕНЯЕМ ОЧИСТКУ
        fix = agent.clean_code(raw_fix)
        
        if "name:" in fix and fix != current_pub.strip():
            with open(pub_path, "w") as f:
                f.write(fix)
            with open("agent_status.env", "w") as f:
                f.write("CHANGES_DETECTED=true\n")
            print("AGENT: Код очищен и применен.")

if __name__ == "__main__":
    main()
