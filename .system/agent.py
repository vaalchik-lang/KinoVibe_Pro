import os
import requests
import re

class SmartAgent:
    def __init__(self):
        raw_keys = os.getenv("GEMINI_API_KEYS", "")
        self.key_pool = [k.strip() for k in raw_keys.split(",") if k.strip()]
        self.current_key_idx = 0

    def clean_code(self, text):
        # Удаляем Markdown и лишние пробелы/символы в начале
        cleaned = re.sub(r'```[a-zA-Z]*\n', '', text)
        cleaned = cleaned.replace('```', '')
        return cleaned.strip()

    def ask_gemini(self, prompt):
        if not self.key_pool: return None
        key = self.key_pool[self.current_key_idx]
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
        try:
            response = requests.post(url, json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"temperature": 0.1}
            }, timeout=30)
            return response.json()['candidates'][0]['content']['parts'][0]['text']
        except:
            return None

def main():
    log_path = "build_error.log"
    pub_path = "client/pubspec.yaml"
    status_path = "agent_status.env"

    with open(status_path, "w") as f: f.write("CHANGES_DETECTED=false\n")

    if not os.path.exists(pub_path): return

    with open(pub_path, "r") as f:
        content = f.read()

    # СРАЗУ ЧИСТИМ, если файл уже испорчен Markdown тегами
    if content.startswith("```") or "```" in content:
        print("AGENT: Обнаружен мусор в файле. Запуск санитизации...")
        sanitized = re.sub(r'```[a-zA-Z]*\n', '', content).replace('```', '').strip()
        with open(pub_path, "w") as f: f.write(sanitized)
        with open(status_path, "w") as f: f.write("CHANGES_DETECTED=true\n")
        return

    log_data = "No log"
    if os.path.exists(log_path):
        with open(log_path, "r") as f: log_data = f.read()[-3000:]

    agent = SmartAgent()
    prompt = f"Fix Flutter pubspec.yaml.\nError: {log_data}\nContent:\n{content}\nReturn ONLY clean YAML."
    
    res = agent.ask_gemini(prompt)
    if res:
        clean_res = agent.clean_code(res)
        if "name:" in clean_res and clean_res != content.strip():
            with open(pub_path, "w") as f: f.write(clean_res)
            with open(status_path, "w") as f: f.write("CHANGES_DETECTED=true\n")
            print("AGENT: Решение применено.")

if __name__ == "__main__":
    main()
