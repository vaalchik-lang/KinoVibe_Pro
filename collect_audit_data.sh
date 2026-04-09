#!/bin/bash
# Дата: 09.04.2026 | Версия: 1.0 | Цель: Сбор кода для анализа

PROJECT_DIR="/storage/emulated/0/Documents/ПРОМТЫ/KINOVIBE"
CLIENT_DIR="$PROJECT_DIR/client"

echo "=== START OF AUDIT DATA ==="
echo "PROJECT_PATH: $PROJECT_DIR"

echo "--- FILE: pubspec.yaml ---"
cat "$CLIENT_DIR/pubspec.yaml"

echo -e "\n--- FILE: lib/models/movie_model.dart ---"
cat "$CLIENT_DIR/lib/models/movie_model.dart"

echo -e "\n--- FILE: lib/screens/home_screen.dart ---"
cat "$CLIENT_DIR/lib/screens/home_screen.dart"

echo -e "\n--- FILE: lib/services/api_service.dart ---"
cat "$CLIENT_DIR/lib/services/api_service.dart"

echo -e "\n--- FILE: lib/services/webrtc_service.dart ---"
[ -f "$CLIENT_DIR/lib/services/webrtc_service.dart" ] && cat "$CLIENT_DIR/lib/services/webrtc_service.dart" || echo "Not found"

echo -e "\n=== END OF AUDIT DATA ==="
