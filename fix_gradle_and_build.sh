#!/bin/bash
# Дата: 2026-04-09 | Цель: Обновление Gradle и Билд | Версия: 1.0

CLIENT_DIR="/content/KINOVIBE/client"
cd $CLIENT_DIR

echo "🔧 [1/3] Обновление структуры проекта (Flutter Repair)..."
# flutter create . обновляет файлы в папке android/ до актуальных
flutter create . --platforms android

echo "📦 [2/3] Очистка кэша и обновление зависимостей..."
flutter clean
flutter pub get

echo "🏗️ [3/3] Повторная попытка сборки APK..."
# Собираем с флагом --multidex, если проект большой
flutter build apk --release --no-tree-shake-icons

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ УСПЕХ: APK собран!"
else
    echo "❌ ОШИБКА: Сборка не удалась."
    exit 1
fi
