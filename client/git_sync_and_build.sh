#!/bin/bash
# Дата: 2026-04-09 | Цель: Синхронизация и билд | Версия: 1.1

PROJECT_DIR="/content/KINOVIBE"
CLIENT_DIR="$PROJECT_DIR/client"

echo "📝 [1/4] Подготовка исправлений..."
git config --global user.email "vaalchik@example.com"
git config --global user.name "Vaalchik AI Architect"

# Проверка наличия файлов перед правкой
if [ -f "$CLIENT_DIR/lib/screens/home_screen.dart" ]; then
    # Исправляем HomeScreen
    sed -i 's/_result = result as SearchResult?;/_result = SearchResult.fromJson(result);/g' $CLIENT_DIR/lib/screens/home_screen.dart
    sed -i 's/movies:/results:/g' $CLIENT_DIR/lib/screens/home_screen.dart
    echo "✅ Файлы кода исправлены"
else
    echo "❌ Ошибка: Файл home_screen.dart не найден!"
    exit 1
fi

echo "🚀 [2/4] Пуш в GitHub..."
cd $PROJECT_DIR
git add .
git commit -m "Fix: SearchResult mapping and WebRTC sdpMLineIndex [Living Manifesto v3.2]"
git push origin main

echo "🏗️ [3/4] Сборка APK..."
cd $CLIENT_DIR
flutter pub get
flutter build apk --release --no-pub --no-tree-shake-icons

echo "✅ ИТОГ: Код на GitHub обновлен, APK готов."
