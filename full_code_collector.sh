#!/bin/bash
# Дата: 09.04.2026 | Версия: 2.0 | Цель: Полный дамп кода для LLM-анализа

PROJECT_DIR="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/client"
OUTPUT_FILE="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE/FULL_PROJECT_DUMP.txt"

# Очистка старого файла
echo "--- KINOVIBE FULL PROJECT DUMP ---" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------" >> "$OUTPUT_FILE"

# 1. Добавляем pubspec.yaml
echo -e "\n[FILE: pubspec.yaml]" >> "$OUTPUT_FILE"
cat "$PROJECT_DIR/pubspec.yaml" >> "$OUTPUT_FILE"

# 2. Рекурсивно собираем все .dart файлы из папки lib
find "$PROJECT_DIR/lib" -name "*.dart" | while read -r file; do
    relative_path=${file#$PROJECT_DIR/}
    echo -e "\n\n[FILE: $relative_path]" >> "$OUTPUT_FILE"
    echo "----------------------------------" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
done

echo "✅ СБОР ЗАВЕРШЕН!"
echo "📍 Файл сохранен: $OUTPUT_FILE"
echo "📊 Размер файла: $(du -h "$OUTPUT_FILE" | cut -f1)"
