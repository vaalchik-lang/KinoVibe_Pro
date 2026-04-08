#!/bin/bash
echo "=== АУДИТ ОКРУЖЕНИЯ KINOVIBE ==="
echo "1. Проверка структуры БД..."
mariadb -u root -e "USE agent_core; DESCRIBE global_knowledge;" && echo "✅ База OK" || echo "❌ База не настроена"

echo "2. Проверка файлов Агента..."
[ -f ".system/meta_agent.py" ] && echo "✅ Агент на месте" || echo "❌ Агент отсутствует"
[ -f ".system/core/key_pool.py" ] && echo "✅ KeyPool на месте" || echo "❌ KeyPool отсутствует"

echo "3. Проверка Flutter..."
flutter --version | head -n 1 || echo "❌ Flutter не найден"

echo "4. Проверка Secrets (локально)..."
[ -f ".system/.env_private" ] && echo "✅ .env_private найден" || echo "⚠️ .env_private отсутствует (но это норм для гита)"
