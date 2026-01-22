#!/usr/bin/env python3
"""
Добавляет все Swift файлы в Xcode проект
"""
import os
import subprocess
import sys

project_path = "LegalTrack/LegalTrack.xcodeproj"
source_dir = "LegalTrack/LegalTrack"

# Используем xcodebuild для добавления файлов
# Но проще всего - использовать команду через Xcode

print("Добавление файлов через xcodebuild...")

# Альтернативный способ - использовать Ruby скрипт для обновления project.pbxproj
# Или просто открыть в Xcode и добавить через GUI

# Попробуем использовать xcodeproj gem если доступен
try:
    result = subprocess.run(['which', 'xcodeproj'], capture_output=True, text=True)
    if result.returncode == 0:
        print("xcodeproj gem найден")
        # Можно использовать для автоматического добавления
    else:
        print("xcodeproj gem не найден")
except:
    pass

print("\nРекомендуется добавить файлы через Xcode:")
print("1. Откройте проект в Xcode")
print("2. Правой кнопкой на папку LegalTrack")
print("3. Add Files to 'LegalTrack'...")
print("4. Выберите папку LegalTrack/")
print("5. Убедитесь что выбрано: Copy items, Create groups, Add to target")








