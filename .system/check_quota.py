import requests
import os

def check_keys():
    # Твой прямой путь из промпта
    env_path = '/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/.system/.env_private'
    
    if not os.path.exists(env_path):
        print(f">> [ERROR]: Файл не найден по адресу: {env_path}")
        return

    keys = []
    with open(env_path, 'r') as f:
        for line in f:
            if "GEMINI_API_KEYS" in line:
                raw_value = line.split('=')[1].strip().replace('"', '').replace("'", "")
                keys = [k.strip() for k in raw_value.split(',') if k.strip()]

    if not keys:
        print(">> [ERROR]: В файле не найдена переменная GEMINI_API_KEYS.")
        return

    print(f">> [INFO]: Проверка {len(keys)} ключей...")
    
    for i, key in enumerate(keys):
        # Используем простейший вызов модели для проверки квоты
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
        payload = {"contents": [{"parts": [{"text": "ping"}]}]}
        
        try:
            r = requests.post(url, json=payload, timeout=10)
            status = r.status_code
            
            if status == 200:
                print(f"Key {i+1} [{key[:8]}...]: ✅ ACTIVE")
            elif status == 429:
                print(f"Key {i+1} [{key[:8]}...]: ❌ EXHAUSTED (429 - Limit)")
            else:
                print(f"Key {i+1} [{key[:8]}...]: ⚠️ ERROR {status}")
        except Exception as e:
            print(f"Key {i+1} [{key[:8]}...]: 🔥 TIMEOUT/CONNECTION ERROR")

if __name__ == "__main__":
    check_keys()
