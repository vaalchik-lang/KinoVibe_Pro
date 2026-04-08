# ЭТАП 6: СБОРКА И ДЕПЛОЙ

## 📦 СОСТАВ АРХИВА `KINOVIBE_etap6.tar.gz`
- `.github/workflows/build.yml` — GitHub Actions: сборка APK при пуше
- `colab_build.ipynb` — Jupyter-ноутбук для сборки APK в Google Colab

## ✅ ЧТО СДЕЛАНО

### GitHub Actions
- Триггер: push в main + ручной запуск (workflow_dispatch)
- Flutter 3.24.3 (stable)
- Артефакт: `kinovibe-release` (хранится 7 дней)

### Google Colab
- Полная установка: apt deps → Flutter SDK → Android SDK → лицензии
- Автоматическая сборка `flutter build apk --release`
- Скачивание APK через `files.download()`
- Время сборки: ~10-15 минут

## 🚀 ИСПОЛЬЗОВАНИЕ

### GitHub Actions
```
1. git push origin main
2. GitHub → Actions → "Build APK" → дождись завершения
3. Скачай артефакт kinovibe-release → app-release.apk
```

### Google Colab
```
1. Открой colab_build.ipynb в Google Colab
2. Runtime → Run all
3. Через ~15 минут браузер предложит скачать APK
```

### Локально (компьютер)
```bash
cd client
flutter pub get
flutter build apk --release
# → client/build/app/outputs/flutter-apk/app-release.apk
```

### Внешний сервер (Yandex Cloud)
```bash
flutter build apk --release --dart-define=USE_REMOTE=true
```

## ⏳ ЧТО ОСТАЛОСЬ
- Подписать APK release keystore (для Google Play)
- WebRTC (Этап 4-5)

## 🔗 ФИНАЛЬНЫЙ ПРОМТ ДЛЯ LLM (если всё собрано)
```
Проект KinoVibe полностью реализован (этапы 1-3, 6).
Требуется доработка:
1. WebRTC совместный просмотр (этап 4) — см. README_ETAP_3.md
2. Интеграционное тестирование (этап 5)
3. Замени <PUBLIC_IP> в api_config.dart на реальный IP Yandex Cloud
4. Замени vault.json на реальные ключи Gemini и Groq

После заполнения ключей — собери APK через GitHub Actions или Colab.
```
