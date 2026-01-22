# Инструкция по настройке Xcode проекта

## Быстрый старт

### Вариант 1: Создание проекта через Xcode GUI (Рекомендуется)

1. **Откройте Xcode**
2. **File → New → Project**
3. Выберите **iOS → App**
4. Заполните:
   - **Product Name**: `LegalTrack`
   - **Team**: Выберите свою команду
   - **Organization Identifier**: `com.legaltrack` (или ваш)
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None` (или SwiftData если нужно)
5. **Сохраните проект** в папку `/Users/mait/legaltrackswift/`
6. **Замените содержимое** созданного проекта нашими файлами:
   - Скопируйте все файлы из `LegalTrack/` в созданный проект
   - Удалите автоматически созданные файлы (ContentView.swift, если он конфликтует)

### Вариант 2: Использование существующей структуры

Если у вас уже есть проект, просто добавьте все файлы из папки `LegalTrack/` в проект:

1. Откройте Xcode проект
2. Правой кнопкой на папку проекта → **Add Files to "LegalTrack"...**
3. Выберите папку `LegalTrack/`
4. Убедитесь что выбрано:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: LegalTrack**

## Настройка проекта

### 1. Минимальная версия iOS

Убедитесь что в настройках проекта:
- **iOS Deployment Target**: `18.0`

### 2. Bundle Identifier

В настройках проекта установите:
- **Bundle Identifier**: `com.legaltrack.app` (или ваш)

### 3. Info.plist настройки

Добавьте в Info.plist (или через настройки проекта):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>arbitr.kazna.tech</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 4. Capabilities

Добавьте если нужно:
- **Keychain Sharing** (для хранения токенов)
- **Background Modes** (если нужны push-уведомления)

## Структура файлов в проекте

После добавления файлов структура должна быть:

```
LegalTrack/
├── App/
│   └── LegalTrackApp.swift
├── Core/
│   ├── Network/
│   │   ├── APIService.swift
│   │   ├── Endpoints.swift
│   │   └── Models/
│   │       ├── User.swift
│   │       ├── Case.swift
│   │       ├── Notification.swift
│   │       └── Message.swift
│   ├── Storage/
│   │   ├── KeychainManager.swift
│   │   └── UserDefaultsManager.swift
│   ├── Utils/
│   │   ├── Constants.swift
│   │   └── Extensions/
│   │       ├── String+Extensions.swift
│   │       └── Date+Extensions.swift
│   └── Theme/
│       ├── Colors.swift
│       ├── Typography.swift
│       └── Spacing.swift
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── AuthView.swift
│   │   │   ├── PhoneInputView.swift
│   │   │   └── CodeInputView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   ├── Main/
│   │   ├── Views/
│   │   │   ├── MainTabView.swift
│   │   │   └── MainView.swift
│   │   └── ViewModels/
│   │       └── MainViewModel.swift
│   ├── Notifications/
│   │   └── Views/
│   │       └── NotificationsView.swift
│   ├── Calendar/
│   │   └── Views/
│   │       └── CalendarView.swift
│   └── Delays/
│       └── Views/
│           └── DelaysView.swift
└── Shared/
    └── Components/
        ├── Buttons/
        │   └── PrimaryButton.swift
        └── Cards/
            └── CaseCard.swift
```

## Проверка компиляции

После добавления всех файлов:

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)

Если есть ошибки компиляции, проверьте:
- Все файлы добавлены в target
- Нет дублирующихся файлов
- Правильные импорты

## Запуск

1. Выберите симулятор или устройство
2. **Product → Run** (⌘R)

## API настройка

API endpoint уже настроен в `Core/Utils/Constants.swift`:
```swift
static let baseURL = "https://arbitr.kazna.tech"
```

Если нужно изменить, отредактируйте этот файл.

## Возможные проблемы

### Ошибка компиляции "Cannot find type"
- Убедитесь что все файлы добавлены в target
- Проверьте что нет циклических зависимостей

### Ошибка сети
- Проверьте что API доступен
- Проверьте настройки App Transport Security

### Ошибка Keychain
- Убедитесь что добавлена capability "Keychain Sharing"

---

**Готово!** Теперь проект должен компилироваться и запускаться.








