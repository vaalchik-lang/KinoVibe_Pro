# 🎬 KinoVibe v3.0

> Кинематографический AI. Он чувствует твоё настроение и находит фильм, который ты хочешь увидеть, но не можешь вспомнить название.

**Эстетика:** Tropical Noir / Steampunk Bronze

---

## Архитектура

```
Пользователь → [голос/текст] → FastAPI сервер
                                    ↓
                          LLM (Gemini/Groq) — формирует поисковый запрос
                                    ↓
                          yt-dlp — ищет видео на YouTube
                                    ↓
                          Flutter → карточки → плеер
```

---

## Быстрый старт (Termux)

### 1. Сервер

```bash
cd /storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/server

# Установить зависимости
pip install -r requirements.txt

# Заполнить ключи
nano vault.json

# Запустить
python main.py
```

### 2. Проверить

```bash
curl http://127.0.0.1:8000/health

curl -X POST http://127.0.0.1:8000/search \
  -H "Content-Type: application/json" \
  -d '{"query": "хочу что-то тёплое и грустное", "category": "movies"}'
```

---

## Сборка APK

### Вариант 1: На компьютере (рекомендуется)

```bash
# Установи Flutter: https://docs.flutter.dev/get-started/install
cd client
flutter pub get
flutter build apk --release
# APK: client/build/app/outputs/flutter-apk/app-release.apk
```

### Вариант 2: GitHub Actions

1. Запушь код в репозиторий
2. Actions → "Build APK" → Run workflow
3. Скачай APK из артефактов

### Вариант 3: Google Colab

1. Открой `colab_build.ipynb`
2. Runtime → Run all
3. Скачай APK (~15 минут)

---

## Деплой на Yandex Cloud

```bash
./server/deploy.sh <PUBLIC_IP> ~/.ssh/your-key.pem
```

Подробнее: [server/README_DEPLOY.md](server/README_DEPLOY.md)

---

## Структура проекта

```
KINOVIBE/
├── server/
│   ├── main.py           # FastAPI: /health, /search, /pool/status
│   ├── key_pool.py       # Ротация 7 Gemini + 5 Groq ключей
│   ├── search.py         # LLM → поисковый запрос → yt-dlp
│   ├── vault.json        # API ключи (не коммитить!)
│   ├── Dockerfile        # Контейнеризация
│   ├── deploy.sh         # Скрипт деплоя на VM
│   └── README_DEPLOY.md  # Инструкция для Yandex Cloud
├── client/
│   └── lib/
│       ├── main.dart
│       ├── theme/         # Tropical Noir цвета
│       ├── screens/       # HomeScreen, PlayerScreen
│       ├── widgets/       # TransformerWidget, MoodDialog, MovieCard
│       ├── services/      # ApiService, ApiConfig
│       └── models/        # MovieItem, SearchResult
├── .github/workflows/
│   └── build.yml         # GitHub Actions APK сборка
├── colab_build.ipynb     # Сборка в Google Colab
└── README.md
```

---

## Этапы разработки

| Этап | Статус | Описание |
|------|--------|----------|
| 1 — Фундамент | ✅ | Структура, vault.json, ассеты |
| 2 — Сервер | ✅ | FastAPI, KeyPool, yt-dlp |
| 3 — Flutter UI | ✅ | Трансформер, диалог, карточки, плеер |
| 4 — WebRTC | ⏳ | Совместный просмотр |
| 5 — Интеграция | ⏳ | Голос + полный цикл |
| 6 — Сборка | ✅ | APK + Docker + Yandex Cloud |
