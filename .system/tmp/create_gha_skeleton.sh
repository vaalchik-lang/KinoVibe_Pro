#!/bin/bash
# 1. Создаем структуру папок
mkdir -p .github/workflows
mkdir -p .system/core

# 2. Создаем SQL-схему для инициализации базы в облаке
cat << 'SQL' > .system/schema.sql
CREATE TABLE IF NOT EXISTS global_knowledge (
    id INT AUTO_INCREMENT PRIMARY KEY,
    context_tag VARCHAR(50),
    pattern_name VARCHAR(100),
    problem_signature TEXT,
    solution_payload LONGTEXT,
    source_url VARCHAR(255),
    reliability_index INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
SQL

# 3. Создаем файл конфигурации линтера (п.14 Манифеста)
cat << 'YAML' > analysis_options.yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    - prefer_const_constructors
    - avoid_empty_catch
    - cancel_subscriptions
YAML

# 4. Создаем основной Workflow для сборки APK
cat << 'YAML' > .github/workflows/main.yml
name: KINOVIBE_TERMINAL_BUILD

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    services:
      mariadb:
        image: mariadb:10.6
        env:
          MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: 'yes'
          MARIADB_DATABASE: 'agent_core'
        ports:
          - 3306:3306
        options: --health-cmd="mariadb-admin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Setup Python & DB
        run: |
          sudo apt-get update
          sudo apt-get install -y mariadb-client
          pip install mysql-connector-python requests
          mysql -h 127.0.0.1 -u root agent_core < .system/schema.sql

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        id: flutter_build
        continue-on-error: true
        run: flutter build apk --release > build_output.log 2>&1

      - name: Agent Intervention (Auto-Fix)
        if: steps.flutter_build.outcome == 'failure'
        env:
          SERPER_API_KEY: ${{ secrets.SERPER_API_KEY }}
          GEMINI_API_KEYS: ${{ secrets.GEMINI_API_KEYS }}
        run: |
          echo ">> [CRITICAL]: Билд упал. Агент анализирует логи..."
          LOG_TAIL=$(tail -n 100 build_output.log)
          python .system/meta_agent.py "$LOG_TAIL"
          exit 1

      - name: Upload APK
        if: steps.flutter_build.outcome == 'success'
        uses: actions/upload-artifact@v4
        with:
          name: kinovibe-release
          path: build/app/outputs/flutter-apk/app-release.apk
YAML

# 5. Инициализация GIT (п.16 Манифеста с фиксом v3.2)
if [ -d ".git" ]; then
    git add .
    git commit -m "Update: GHA Skeleton & Manifesto v3.1 [AUTO-v3.3]"
else
    git init
    echo "*.log" > .gitignore
    echo ".env*" >> .gitignore
    git add .
    git commit -m "Initial commit: KINOVIBE Core v3.1"
fi
