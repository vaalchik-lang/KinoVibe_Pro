# ЭТАП 2: PYTHON-СЕРВЕР

## 📦 СОСТАВ АРХИВА `KINOVIBE_etap2.tar.gz`
- `server/main.py` — FastAPI: /health, /search, /pool/status
- `server/key_pool.py` — ротация 7 Gemini + 5 Groq, exponential backoff
- `server/search.py` — LLM → поисковый запрос → yt-dlp
- `server/requirements.txt` — зависимости Python
- `server/Dockerfile` — контейнер для Yandex Cloud
- `server/deploy.sh` — скрипт деплоя (chmod +x перед запуском)
- `server/README_DEPLOY.md` — инструкция для Yandex Cloud VM

## ✅ ЧТО СДЕЛАНО
- KeyPool: round-robin по 7+5 ключам, блокировка при 429 с exponential backoff (до 5 мин)
- LLM-пайплайн: Gemini → Groq fallback → эвристика
- LLM формирует JSON: `{"query": "...", "mood": "...", "genre": "..."}`
- yt-dlp: `ytsearch8:` → список {title, url, thumbnail, duration, view_count}
- FastAPI с CORS (для Flutter на localhost)
- Docker-образ на python:3.11-slim с ffmpeg

## 🚀 ЗАПУСК В TERMUX
```bash
cd /storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/server
pip install -r requirements.txt
python main.py
```

## 🧪 ТЕСТ
```bash
# Health
curl http://127.0.0.1:8000/health

# Статус ключей
curl http://127.0.0.1:8000/pool/status

# Поиск
curl -X POST http://127.0.0.1:8000/search \
  -H "Content-Type: application/json" \
  -d '{"query": "грустно, хочу что-то тёплое", "category": "movies"}'
```

## ⏳ ЧТО ОСТАЛОСЬ
- Flutter UI (трансформер, диалог, карточки, плеер)
- WebRTC совместный просмотр
- APK сборка

## 🔗 ПРОМТ ДЛЯ СЛЕДУЮЩЕЙ LLM (Этап 3)
```
Ты — разработчик KinoVibe (Tropical Noir / Steampunk Bronze).
Продолжаем с ЭТАПА 3 — Flutter UI.

Что уже есть:
- Python-сервер (FastAPI) на 127.0.0.1:8000
- Эндпоинты: POST /search, GET /health

Твоя задача (этап 3 — Flutter клиент):
1. pubspec.yaml — зависимости (video_player, speech_to_text, flutter_animate, etc.)
2. theme/app_theme.dart — цвета #0A0810 / #B87333 / #D4A843 / #C9924A / #4A7A6B
3. widgets/transformer_widget.dart — круг 220px → 4 лепестка (разлёт 70px) + микрофон
4. widgets/mood_dialog.dart — стекломорфный диалог "Опиши настроение"
5. widgets/movie_card.dart — горизонтальная карточка (постер + название + длительность)
6. screens/home_screen.dart — главный экран со стрелкой вниз (пульсирует)
7. screens/player_screen.dart — VideoPlayer + Play/Pause/Seek/Fullscreen + кнопка "Смотреть вместе"
8. services/api_config.dart — переключалка local/remote URL
9. services/api_service.dart — HTTP POST /search

Запрещено: плоский дизайн, неон, пластик.
Освещение: сверху-слева 30°, глубокие тени.

Критерии готовности:
- Круг открывается → 4 лепестка разлетаются
- Нажатие на лепесток → выбор категории
- Стрелка вниз → диалог настроения → поиск → карточки
- Клик на карточку → плеер

Формат сдачи: архив KINOVIBE_etap3.tar.gz + README_ETAP_3.md
```
