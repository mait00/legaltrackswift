#!/bin/bash

# Автоматическая настройка Xcode проекта
# Этот скрипт создаст базовый проект и добавит инструкции

PROJECT_DIR="/Users/mait/legaltrackswift"
cd "$PROJECT_DIR"

echo "🚀 Настройка Xcode проекта для LegalTrack"
echo ""

# Проверяем наличие Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode не найден. Установите Xcode из App Store."
    exit 1
fi

echo "✅ Xcode найден"
echo ""

# Создаем базовую структуру проекта если её нет
if [ ! -d "LegalTrack.xcodeproj" ]; then
    echo "📦 Создание структуры проекта..."
    mkdir -p LegalTrack.xcodeproj/project.xcworkspace/xcshareddata
    mkdir -p LegalTrack.xcodeproj/xcshareddata/xcschemes
    echo "✅ Структура создана"
else
    echo "✅ Проект уже существует"
fi

echo ""
echo "📝 Следующие шаги:"
echo ""
echo "ВАРИАНТ 1 (Рекомендуется):"
echo "1. Откройте Xcode"
echo "2. File -> New -> Project"
echo "3. iOS -> App"
echo "4. Product Name: LegalTrack"
echo "5. Interface: SwiftUI, Language: Swift"
echo "6. Сохраните в: $PROJECT_DIR"
echo "7. Правой кнопкой на проект -> Add Files to 'LegalTrack'..."
echo "8. Выберите папку LegalTrack/"
echo "9. ✅ Copy items if needed"
echo "10. ✅ Create groups"
echo "11. ✅ Add to targets: LegalTrack"
echo ""
echo "ВАРИАНТ 2 (Если проект уже открыт):"
echo "1. В Xcode: Правой кнопкой на папку проекта"
echo "2. Add Files to 'LegalTrack'..."
echo "3. Выберите папку LegalTrack/"
echo "4. Настройте опции как выше"
echo ""
echo "✅ После добавления файлов проект готов к запуску!"

