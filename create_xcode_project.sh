#!/bin/bash

# Скрипт для создания Xcode проекта

PROJECT_NAME="LegalTrack"
WORKSPACE_DIR="/Users/mait/legaltrackswift"

cd "$WORKSPACE_DIR"

# Создаем проект через Xcode (если доступен)
# Или создаем вручную через открытие Xcode

echo "Для создания Xcode проекта:"
echo "1. Откройте Xcode"
echo "2. File -> New -> Project"
echo "3. Выберите iOS -> App"
echo "4. Название: $PROJECT_NAME"
echo "5. Interface: SwiftUI"
echo "6. Language: Swift"
echo "7. Сохраните в: $WORKSPACE_DIR"
echo ""
echo "После создания проекта скопируйте все файлы из папки LegalTrack/ в проект"








