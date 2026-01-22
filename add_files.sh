#!/bin/bash

# Добавляем файлы в Xcode проект через AppleScript

PROJECT_PATH="/Users/mait/legaltrackswift/LegalTrack/LegalTrack.xcodeproj"
SOURCE_DIR="/Users/mait/legaltrackswift/LegalTrack/LegalTrack"

echo "📦 Добавление файлов в Xcode проект..."

# Открываем проект
open "$PROJECT_PATH"

echo "✅ Проект открыт в Xcode"
echo ""
echo "Теперь в Xcode:"
echo "1. Правой кнопкой на папку 'LegalTrack' в навигаторе"
echo "2. Выберите 'Add Files to \"LegalTrack\"...'"
echo "3. Выберите папку LegalTrack/ (из текущей директории)"
echo "4. Убедитесь что выбрано:"
echo "   ✅ Copy items if needed"
echo "   ✅ Create groups"
echo "   ✅ Add to targets: LegalTrack"
echo "5. Нажмите Add"

