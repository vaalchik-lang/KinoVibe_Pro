#!/bin/bash
OUTPUT="full_project_code_safe.txt"
# Игнорируем любые файлы, которые могут содержать ключи
find . -type f \( -name "*.dart" -o -name "*.py" -o -name "*.yaml" \) \
    -not -path "*/.*" \
    -not -path "*env*" \
    -not -path "*vault*" \
    -not -path "*build*" | while read file; do
    echo "FILE: $file" >> $OUTPUT
    # Маскируем потенциальные ключи при сборке (простая замена)
    sed 's/gsk_[a-zA-Z0-9]\{20,\}/[SECRET_REDACTED]/g' "$file" >> $OUTPUT
done
