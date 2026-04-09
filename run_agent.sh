#!/bin/bash
# Путь к нашему "мозгу"
AGENT_PATH="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/.system/meta_agent.py"
ENV_PATH="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/.system/.env_private"

# Проверка MariaDB
if ! pgrep -x "mariadbd" > /dev/null
then
    echo ">> [SYSTEM]: Запуск MariaDB..."
    mariadbd-safe --datadir=$PREFIX/var/lib/mysql > /dev/null 2>&1 &
    sleep 2
fi

# Загрузка ключей в окружение и запуск
if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' $ENV_PATH | xargs)
    python "$AGENT_PATH" "$@"
else
    echo ">> [ERROR]: .env_private не найден!"
fi
