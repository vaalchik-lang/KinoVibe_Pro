import time
import os

class KeyEntry:
    def __init__(self, value):
        self.value = value
        self.is_active = True
        self.last_used = 0
        self.cooldown_until = 0

class KeyPool:
    def __init__(self, keys_str):
        self.keys = [KeyEntry(k.strip()) for k in keys_str.split(',') if k.strip()]
        self.current_index = 0

    def get_best(self, prefer="gemini"):
        now = time.time()
        # Ищем первый доступный ключ, у которого вышел срок Cooldown
        for _ in range(len(self.keys)):
            key = self.keys[self.current_index]
            self.current_index = (self.current_index + 1) % len(self.keys)
            
            if key.is_active and now > key.cooldown_until:
                return key, prefer
        
        # Если все ключи в Cooldown — принудительно ждем
        print(">> [CRITICAL]: Все ключи исчерпаны. Ожидание сброса квот (60с)...")
        time.sleep(60)
        return self.get_best(prefer)

    def report(self, key_entry, status_code, latency=0):
        if status_code == 429:
            print(f">> [WARN]: Ключ {key_entry.value[:8]}... заблокирован (429). Cooldown 65s.")
            key_entry.cooldown_until = time.time() + 65
        elif status_code != 200:
            print(f">> [ERROR]: Ключ {key_entry.value[:8]}... ошибка {status_code}. Отключение на 5 мин.")
            key_entry.cooldown_until = time.time() + 300

def get_pool():
    keys = os.getenv("GEMINI_API_KEYS", "")
    if not keys:
        # Пытаемся взять из локального .env_private если мы в Termux
        try:
            with open('.env_private', 'r') as f:
                for line in f:
                    if "GEMINI_API_KEYS" in line:
                        keys = line.split('=')[1].strip().strip('"')
        except: pass
    return KeyPool(keys)
