#!/bin/bash
# Дата: 09.04.2026 | Версия: 1.3 | Локация: Termux

# 1. Установка путей
BASE_PATH="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE"
CLIENT_DIR="$BASE_PATH/client"
TARGET_FILE="$CLIENT_DIR/lib/screens/home_screen.dart"

echo "📂 [1/3] Переход в рабочую область..."
cd "$CLIENT_DIR" || exit

# 2. Применение Hotfix (если файлы еще не исправлены)
if [ -f "$TARGET_FILE" ]; then
    echo "🔧 [2/3] Применение патча маппинга..."
    sed -i 's/_result = result as SearchResult?;/_result = SearchResult.fromJson(result);/g' "$TARGET_FILE"
    sed -i 's/movies:/results:/g' "$TARGET_FILE"
else
    echo "❌ Ошибка: Файл не найден по пути $TARGET_FILE"
    exit 1
fi

# 3. Синхронизация с GitHub (Push исправлений)
echo "🚀 [3/3] Синхронизация репозитория..."
git config --global user.email "vaalchik@example.com"
git config --global user.name "Vaalchik AI Architect"

cd "$BASE_PATH"
git add .
git commit -m "Fix: SearchResult mapping in local Termux environment [v3.2]"
git push origin main

echo "✅ ГОТОВО! Код исправлен локально и отправлен на GitHub."
echo "➡️ Для сборки APK в Colab просто перезапусти Шаг 4 (Clone) и Шаг 5 (Build)."
