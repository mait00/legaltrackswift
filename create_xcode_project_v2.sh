#!/bin/bash

# Создание Xcode проекта через шаблон

PROJECT_DIR="/Users/mait/legaltrackswift"
PROJECT_NAME="LegalTrack"

# Создаем временную директорию для шаблона
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Пытаемся создать проект через xcodebuild template (если доступно)
# Или создаем базовую структуру

# Альтернативный подход: создаем project.pbxproj вручную с правильной структурой
cd "$PROJECT_DIR"

# Создаем workspace если нужно
mkdir -p LegalTrack.xcodeproj/project.xcworkspace
mkdir -p LegalTrack.xcodeproj/xcshareddata/xcschemes

echo "Project structure created. Please add files manually in Xcode:"
echo "1. Open Xcode"
echo "2. File -> Add Files to 'LegalTrack'..."
echo "3. Select LegalTrack/ folder"
echo "4. Make sure 'Copy items if needed' and 'Create groups' are checked"

