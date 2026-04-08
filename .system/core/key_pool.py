import math
import os
import random
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

# Заглушка для лога, так как memory.storage может отсутствовать
def log(tag, msg, detail="", level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] [{level}] [{tag}] {msg} {detail}")

@dataclass
class KeyEntry:
    key:              str
    index:            int
    provider:         str
    cooldown_until:   float  = 0.0
    last_error:       Optional[int] = None
    calls_ok:         int   = 0
    calls_err:        int   = 0
    tokens_total:     int   = 0
    consecutive_429:  int   = 0
    consecutive_5xx:  int   = 0
    last_used:        float = 0.0

    @property
    def available(self) -> bool:
        return bool(self.key) and time.time() >= self.cooldown_until

    @property
    def value(self) -> str:
        return self.key

    def on_success(self, tokens: int = 0) -> None:
        self.calls_ok += 1
        self.tokens_total += tokens
        self.last_used = time.time()
        self.consecutive_429 = 0

    def on_error(self, code: int) -> None:
        self.calls_err += 1
        if code == 429:
            self.consecutive_429 += 1
            wait = min(60.0 * (2.0 ** (self.consecutive_429 - 1)), 3600.0)
            self.cooldown_until = time.time() + wait
        elif code == 403:
            self.cooldown_until = time.time() + 3600.0

class ProviderPool:
    def __init__(self, provider: str, keys: list[str]) -> None:
        self.provider = provider
        self._entries = [KeyEntry(key=k, index=i+1, provider=provider) for i, k in enumerate(keys)]
        self._cursor = 0
        self._lock = threading.Lock()

    def get_key(self):
        with self._lock:
            n = len(self._entries)
            for i in range(n):
                e = self._entries[(self._cursor + i) % n]
                if e.available:
                    self._cursor = (self._entries.index(e) + 1) % n
                    return e
            raise Exception(f"All {self.provider} keys exhausted")

class KeyPool:
    _instance = None
    def __init__(self):
        self._gemini = None
        self._ready = False

    def init(self):
        if self._ready: return self
        csv = os.environ.get("GEMINI_API_KEYS", "")
        keys = [k.strip() for k in csv.split(",") if k.strip()]
        self._gemini = ProviderPool("gemini", keys)
        self._ready = True
        return self

    def get_best(self, prefer="gemini"):
        self.init()
        return self._gemini.get_key(), "gemini"

    def report(self, entry, code, tokens=0, latency=0.0, model=""):
        if code == 200: entry.on_success(tokens)
        else: entry.on_error(code)

def get_pool():
    if KeyPool._instance is None:
        KeyPool._instance = KeyPool().init()
    return KeyPool._instance
