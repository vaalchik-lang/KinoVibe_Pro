# ЭТАП 4: WebRTC — СОВМЕСТНЫЙ ПРОСМОТР

## 📦 СОСТАВ АРХИВА `KINOVIBE_etap4.tar.gz`
- `server/signaling.py` — WebSocket сигнальный сервер (комнаты, relay SDP/ICE, синхронизация)
- `server/main.py` — обновлён: добавлены `/rooms/create`, `/rooms`, `/ws/{peer_id}`
- `client/lib/services/webrtc_service.dart` — P2P WebRTC + WebSocket клиент
- `client/lib/screens/room_screen.dart` — экран комнаты (плеер + синхронизация + чат)
- `client/lib/screens/player_screen.dart` — обновлён: кнопка "Смотреть вместе" → RoomScreen
- `client/pubspec.yaml` — добавлен `web_socket_channel`

## ✅ ЧТО СДЕЛАНО

### Сервер (signaling.py)
- Комнаты: `create_room` / `join_room` — до 8 участников
- Relay: SDP offer/answer, ICE candidates между пирами
- Синхронизация: `sync` (play/pause/seek) → broadcast всем в комнате
- Хранение состояния плеера: новый участник сразу получает `is_playing` + `position_sec`
- Чат: текстовые сообщения внутри комнаты
- Keepalive: ping/pong каждые 20 секунд

### Клиент (webrtc_service.dart)
- WebSocket подключение к `/ws/{peer_id}`
- Уникальный peer_id: 8 символов, генерируется при создании сервиса
- createRoom / joinRoom / sendPlay / sendPause / sendSeek / sendChat
- Stream-события: onSync, onPeer, onChat, onError
- RTCPeerConnection: STUN Google, автоматический offer при `peer_joined`

### Экран комнаты (room_screen.dart)
- VideoPlayer + синхронизированные Play/Pause/Seek
- Баннер с ссылкой-приглашением + кнопка "Копировать"
- Счётчик участников в AppBar
- Встроенный чат (системные сообщения + текст)

## 🧪 ТЕСТ (локально)
```bash
# Запустить сервер
python main.py

# Создать комнату
curl -X POST http://127.0.0.1:8000/rooms/create \
  -H "Content-Type: application/json" \
  -d '{"movie_url": "https://...", "movie_title": "Тест"}'
# → {"room_id": "AB12CD34"}

# Список комнат
curl http://127.0.0.1:8000/rooms

# WebSocket тест (wscat)
wscat -c ws://127.0.0.1:8000/ws/peer1
# → {"type": "create_room", "movie_url": "...", "movie_title": "..."}
```

## ⏳ ЧТО ОСТАЛОСЬ
- Этап 5: интеграционный тест полного цикла Голос → Поиск → Плеер → Комната
- Подписать APK для релиза (keystore)

## 🔗 ПРОМТ ДЛЯ СЛЕДУЮЩЕЙ LLM (Этап 5 — Интеграция)
```
Ты — разработчик KinoVibe (Flutter + FastAPI + WebRTC).
Продолжаем с ЭТАПА 5 — финальная интеграция и тесты.

Что уже работает:
- Python-сервер: /search (LLM→yt-dlp), /ws (WebRTC сигнализация), /rooms
- Flutter-клиент: Трансформер → MoodDialog → карточки → плеер → RoomScreen
- Синхронизация play/pause/seek через WebSocket

Задача (этап 5):
1. Проверить и починить полный цикл:
   Голос/текст → POST /search → карточки → VideoPlayer → кнопка "Смотреть вместе" → RoomScreen
2. Добавить обработку ошибок в HomeScreen (нет связи с сервером → показать заглушку)
3. Добавить экран "Присоединиться по коду" (ввести room_id вручную)
4. Протестировать WebSocket синхронизацию (два эмулятора или телефон + браузер)
5. Собрать финальный APK

Формат сдачи: KINOVIBE_etap5.tar.gz + README_ETAP_5.md
```
