# ЭТАП 1: ФУНДАМЕНТ

## 📦 СОСТАВ АРХИВА `KINOVIBE_etap1.tar.gz`
- `README.md` — описание проекта
- `.gitignore` — vault.json и build папки исключены
- `server/vault.json` — шаблон ключей (7 Gemini + 5 Groq)
- `logs/` — пустая папка для логов
- `client/assets/images/` — папка для 9 UI-ассетов

## ✅ ЧТО СДЕЛАНО
- Структура папок создана
- vault.json подготовлен (заполни своими ключами)
- .gitignore настроен (vault.json не попадёт в git)
- README.md с общей документацией

## 🔑 ПЕРЕД ЭТАПОМ 2: ЗАПОЛНИ КЛЮЧИ
```json
// server/vault.json
{
  "gemini_keys": ["AIza...", "AIza...", ... (7 штук)],
  "groq_keys": ["gsk_...", ... (5 штук)]
}
```

## 🚀 ЧТО ДЕЛАТЬ ДАЛЬШЕ (Этап 2)
```bash
# Распаковать в Termux
cd /storage/emulated/0/Documents/ПРОМТЫ/
tar -xzf KINOVIBE_etap1.tar.gz

# Передать архив этапа 1 следующей LLM вместе с промтом ниже
```

## ⏳ ЧТО ОСТАЛОСЬ
- Python-сервер (FastAPI, KeyPool, yt-dlp)
- Flutter-клиент
- WebRTC совместный просмотр
- APK сборка и деплой

## 🔗 ПРОМТ ДЛЯ СЛЕДУЮЩЕЙ LLM (Этап 2)
```
Ты — разработчик проекта KinoVibe (кино-AI на Tropical Noir / Steampunk Bronze).
Продолжаем с ЭТАПА 2.

Что уже есть (архив этапа 1):
- Структура папок
- vault.json с 7 Gemini + 5 Groq ключами
- .gitignore, README.md

Твоя задача (этап 2 — Python-сервер):
1. key_pool.py — ротация 7+5 ключей, exponential backoff, thread-safe
2. search.py — LLM (Gemini→Groq fallback) формирует поисковый запрос → yt-dlp
3. main.py — FastAPI: POST /search, GET /health, GET /pool/status
4. requirements.txt — fastapi, uvicorn, httpx, yt-dlp, pydantic
5. Dockerfile + deploy.sh + README_DEPLOY.md для Yandex Cloud VM

Проверка готовности:
curl http://127.0.0.1:8000/health → {"status":"ok"}
curl -X POST .../search -d '{"query":"грустно, тёплое","category":"movies"}'

Формат сдачи: архив KINOVIBE_etap2.tar.gz + README_ETAP_2.md
```
