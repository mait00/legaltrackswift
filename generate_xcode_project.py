#!/usr/bin/env python3
"""
Генератор Xcode проекта для LegalTrack
Создает правильный project.pbxproj файл со всеми Swift файлами
"""

import os
import uuid
import json
from pathlib import Path

def generate_uuid():
    """Генерирует UUID для Xcode проекта"""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def find_swift_files(root_dir):
    """Находит все Swift файлы в директории"""
    swift_files = []
    for root, dirs, files in os.walk(root_dir):
        # Пропускаем скрытые директории
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, root_dir)
                swift_files.append(rel_path)
    return sorted(swift_files)

def create_file_reference_uuid(file_path):
    """Создает UUID для файла на основе его пути"""
    return hashlib.md5(file_path.encode()).hexdigest()[:24].upper()

# Находим все Swift файлы
project_root = Path(__file__).parent
legal_track_dir = project_root / "LegalTrack"
swift_files = find_swift_files(str(legal_track_dir))

print(f"Найдено {len(swift_files)} Swift файлов")

# Генерируем UUID для проекта
project_uuid = generate_uuid()
print(f"Project UUID: {project_uuid}")

# Создаем базовую структуру project.pbxproj
# Это упрощенная версия, полная версия очень сложная
# Лучше использовать готовый шаблон

print("\nДля полной автоматизации рекомендуется:")
print("1. Открыть Xcode")
print("2. File -> New -> Project -> iOS App")
print("3. Добавить файлы через 'Add Files to LegalTrack...'")
print("\nИли использовать готовый шаблон проекта.")








