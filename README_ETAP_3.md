# ЭТАП 3: FLUTTER UI

## 📦 СОСТАВ АРХИВА `KINOVIBE_etap3.tar.gz`
- `client/pubspec.yaml`
- `client/lib/main.dart`
- `client/lib/theme/app_theme.dart` — цветовая система
- `client/lib/models/movie_model.dart` — MovieItem, SearchResult
- `client/lib/services/api_config.dart` — local/remote переключалка
- `client/lib/services/api_service.dart` — HTTP-клиент
- `client/lib/widgets/transformer_widget.dart` — круг + лепестки + микрофон
- `client/lib/widgets/mood_dialog.dart` — стекломорфный диалог
- `client/lib/widgets/movie_card.dart` — карточка фильма
- `client/lib/screens/home_screen.dart` — главный экран
- `client/lib/screens/player_screen.dart` — плеер

## ✅ ЧТО СДЕЛАНО
- Цвета: background #0A0810, bronze #B87333, gold #D4A843
- TransformerWidget: диск 220px → 4 лепестка (разлёт 90px) + микрофон в центре
- Анимации: expand/collapse (400ms, easeOutBack), пульсация стрелки
- MoodDialog: BackdropFilter blur, стекломорфный контейнер
- MovieCard: CachedNetworkImage + постер + название + длительность
- HomeScreen: стрелка вниз пульсирует, результаты — горизонтальный список
- PlayerScreen: VideoPlayer + Play/Pause/±10s/Fullscreen + кнопка "Смотреть вместе"
- ApiConfig: --dart-define=USE_REMOTE=true переключает на Yandex Cloud

## 📱 СБОРКА APK
```bash
# На компьютере с Flutter
cd client
flutter pub get
flutter build apk --release

# С внешним сервером
flutter build apk --release --dart-define=USE_REMOTE=true
```

## ⏳ ЧТО ОСТАЛОСЬ
- WebRTC комнаты для совместного просмотра (Этап 4)
- Полная интеграция голос → плеер (Этап 5)

## 🔗 ПРОМТ ДЛЯ СЛЕДУЮЩЕЙ LLM (Этап 4 — WebRTC)
```
Ты — разработчик KinoVibe (Flutter + FastAPI).
Продолжаем с ЭТАПА 4 — WebRTC совместный просмотр.

Что уже есть:
- Python-сервер (FastAPI) — рабочий
- Flutter-клиент с плеером — рабочий
- В PlayerScreen есть кнопка "Смотреть вместе" (заглушка)

Твоя задача (этап 4):
1. Добавить flutter_webrtc в pubspec.yaml
2. services/webrtc_service.dart — создание P2P комнаты, DataChannel для синхронизации
3. screens/room_screen.dart — экран комнаты (ссылка-приглашение + статус участников)
4. Синхронизация: play/pause/seek через DataChannel
5. Генерация ссылки: kinovibe://room/<uuid>
6. Сигнальный сервер: простой WebSocket на FastAPI (server/signaling.py)

Критерии готовности:
- Создать комнату → скопировать ссылку → второй пользователь подключается
- Play/Pause синхронизируется между участниками

Формат сдачи: diff-файлы или полный архив KINOVIBE_etap4.tar.gz + README_ETAP_4.md
```
