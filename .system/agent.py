import os
import sys
import requests
import json

# Интеграция с твоим KeyPool логикой
def get_gemini_response(prompt):
    api_key = os.getenv("GEMINI_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    headers = {'Content-Type': 'application/json'}
    data = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2}
    }
    response = requests.post(url, headers=headers, json=data)
    return response.json()['candidates'][0]['content']['parts'][0]['text']

def run_repair():
    print("AGENT: Анализ логов сборки...")
    
    # Загружаем контекст
    with open("build_error.log", "r") as f:
        error_log = f.read()[-2000:] # Последние 2000 символов
        
    with open("client/pubspec.yaml", "r") as f:
        pubspec = f.read()

    prompt = f"""
    Ты — Autonomous AI Agent для проекта KINOVIBE. 
    Сборка упала. Вот лог ошибки:
    {error_log}

    Вот текущий pubspec.yaml:
    {pubspec}

    Найди причину ошибки. Если это конфликт зависимостей, выдай ИСПРАВЛЕННЫЙ текст файла pubspec.yaml целиком.
    Отвечай ТОЛЬКО чистым кодом файла, без пояснений.
    """

    print("AGENT: Запрос к Gemini 2.5 Flash...")
    fixed_code = get_gemini_response(prompt)
    
    if "name:" in fixed_code:
        with open("client/pubspec.yaml", "w") as f:
            f.write(fixed_code)
        print("AGENT: Файл pubspec.yaml исправлен.")
    else:
        print("AGENT: Не удалось получить корректный фикс.")

if __name__ == "__main__":
    run_repair()
