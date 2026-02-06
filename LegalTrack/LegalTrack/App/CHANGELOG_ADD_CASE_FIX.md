# Исправление добавления дел

## Проблема
Не работало добавление дел в мониторинг (например, А84-208/2026).

## Внесенные изменения

### 1. AddCaseViewModel.swift
**Изменено:**
- Параметры для добавления дела теперь передаются через URL query parameters вместо JSON body
- Изменен формат: `/subs/add-case?case=А84-208/2026&is_sou=0`
- Добавлена очистка кэша подписок после успешного добавления дела
- Улучшена обработка ошибок с более детальными сообщениями

**Детали изменений в методе `addCase`:**
```swift
// Было:
let requestBody = AddCaseRequest(case: cleanedNumber, isSou: isSou ? 1 : 0)
let response: AddCaseResponse = try await apiService.request(
    endpoint: APIEndpoint.addCase(caseNumber: cleanedNumber, isSou: isSou).path,
    method: .post,
    body: requestBody
)

// Стало:
let endpoint = "/subs/add-case?case=\(cleanedNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanedNumber)&is_sou=\(isSou ? "1" : "0")"
let response: AddCaseResponse = try await apiService.request(
    endpoint: endpoint,
    method: .post
)

// После успешного добавления:
CacheManager.shared.removeCache(forKey: "subscriptions")
```

### 2. Endpoints.swift
**Изменено:**
- Endpoint для `addCase` теперь формирует URL с параметрами
- Параметры: `case` (номер дела) и `is_sou` (тип суда: 0 = АС, 1 = СОЮ)

**Детали:**
```swift
case .addCase(let caseNumber, let isSou):
    let encodedCase = caseNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? caseNumber
    return "/subs/add-case?case=\(encodedCase)&is_sou=\(isSou ? "1" : "0")"
```

### 3. CacheManager.swift
**Добавлено:**
- Новый метод `removeCache(forKey:)` для удаления конкретного кэша
- Поддерживает различные ключи: "subscriptions", "cases_list", "case_XXX", "companies"

**Код:**
```swift
func removeCache(forKey key: String) {
    let fileURL: URL
    
    switch key {
    case "subscriptions", "cases_list":
        fileURL = casesDirectory.appendingPathComponent("cases_list.json")
    case let caseKey where caseKey.hasPrefix("case_"):
        fileURL = casesDirectory.appendingPathComponent("\(caseKey).json")
    case "companies":
        fileURL = cacheDirectory.appendingPathComponent("companies.json")
    default:
        fileURL = cacheDirectory.appendingPathComponent("\(key).json")
    }
    
    try? fileManager.removeItem(at: fileURL)
    UserDefaults.standard.removeObject(forKey: "cache_timestamp_\(key)")
}
```

### 4. AddCaseView.swift
**Добавлено:**
- Автоматическое определение типа суда по номеру дела
- При вводе номера дела, начинающегося с "А" или "Ф" - автоматически выбирается "Арбитражные суды"
- При вводе номера дела, начинающегося с цифры - выбирается "СОЮ"

**Новая функция:**
```swift
private func detectCourtType(from caseNumber: String) {
    let cleaned = caseNumber.trimmingCharacters(in: .whitespaces).uppercased()
    
    // Арбитражные дела: А40, А84, Ф05 и т.д.
    if cleaned.hasPrefix("А") || cleaned.hasPrefix("A") || 
       cleaned.hasPrefix("Ф") || cleaned.hasPrefix("F") {
        selectedCourtType = .arbitration
    }
    // СОЮ дела: 2-1234/2024
    else if cleaned.first?.isNumber == true {
        selectedCourtType = .general
    }
}
```

## Примеры использования

### Добавление арбитражного дела
```
Номер: А84-208/2026
Тип: Арбитражные суды (определяется автоматически)
Запрос: POST /subs/add-case?case=А84-208/2026&is_sou=0
```

### Добавление дела СОЮ
```
Номер: 2-1234/2024
Тип: Суды общей юрисдикции (определяется автоматически)
Запрос: POST /subs/add-case?case=2-1234/2024&is_sou=1
```

## Обработка ошибок

Улучшена обработка следующих ошибок:
- **401 Unauthorized**: "Требуется авторизация"
- **404 Not Found**: "Дело не найдено в системе судов"
- **500+ Server Error**: "Ошибка сервера. Попробуйте позже"
- **Network Error**: "Ошибка сети. Проверьте подключение к интернету"

## Тестирование

Для тестирования исправления:

1. Запустите приложение
2. Перейдите на экран "Добавить дело"
3. Введите номер дела: **А84-208/2026**
4. Убедитесь, что автоматически выбран тип "Арбитражные суды"
5. Нажмите "Найти дело"
6. Нажмите "Добавить в мониторинг"
7. Проверьте, что дело успешно добавлено и появилось в списке

## API Endpoints

### POST /subs/add-case
**Parameters (Query String):**
- `case` (string, required): Номер дела (например, "А84-208/2026")
- `is_sou` (string, required): Тип суда ("0" = АС, "1" = СОЮ)

**Response:**
```json
{
  "message": "Дело успешно добавлено",
  "success": true,
  "status": "success",
  "data": {
    "id": 12345,
    "value": "А84-208/2026"
  }
}
```

## Совместимость с API

Эти изменения совместимы с API старого приложения:
- https://gitlab.com/ios.stavropol/legal.track/-/tree/new_design?ref_type=heads
- Базовый URL: https://arbitr.kazna.tech

## Примечания

- После добавления дела кэш подписок автоматически очищается для обновления списка
- Поиск дела `/subs/search-cases` работает без изменений
- Удаление дела `/subs/remove-case` работает без изменений
