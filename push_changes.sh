#!/bin/bash
# Дата: 09.04.2026 | Версия: 1.1 | Локация: Termux

PROJECT_DIR="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE"

echo "📂 [1/3] Переход в директорию проекта..."
cd "$PROJECT_DIR" || exit

# Настройка пользователя (на случай сброса конфига)
git config --global user.email "vaalchik@example.com"
git config --global user.name "Vaalchik AI Architect"

echo "📝 [2/3] Индексация изменений..."
git add .

# Создаем коммит с таймстампом
COMMIT_MSG="Update: Sync local changes from Termux [$(date +'%Y-%m-%d %H:%M')]"
git commit -m "$COMMIT_MSG"

echo "🚀 [3/3] Форсированная отправка на GitHub..."
# Используем --force, чтобы перезаписать любые конфликты с облаком
git push origin main --force

if [ $? -eq 0 ]; then
    echo "========================================"
    echo "✅ УСПЕХ: Все изменения в GitHub!"
    echo "========================================"
else
    echo "❌ ОШИБКА: Пуш не удался. Проверь интернет или токен."
fi
