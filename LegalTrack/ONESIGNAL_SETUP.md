# Настройка OneSignal Push Уведомлений

## Шаг 1: Установка OneSignal SDK

### Через Swift Package Manager (рекомендуется)

1. Откройте проект в Xcode
2. Перейдите в **File → Add Package Dependencies...**
3. Введите URL: `https://github.com/OneSignal/OneSignal-iOS-SDK`
4. Выберите версию: **5.0.0** или выше
5. Добавьте пакет в target **LegalTrack**

### Через CocoaPods (альтернатива)

Добавьте в `Podfile`:
```ruby
pod 'OneSignal', '~> 5.0'
```

Затем выполните:
```bash
pod install
```

## Шаг 2: Обновление AppDelegate

После установки SDK, раскомментируйте код в `AppDelegate.swift` (код уже добавлен в файл, нужно только раскомментировать):

```swift
import OneSignal

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Настройка уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Инициализация OneSignal (как в старой версии React Native)
        OneSignal.setAppId(AppConstants.OneSignal.appId)
        OneSignal.setLogLevel(.verbose, visualLevel: .none)
        OneSignal.setRequiresUserPrivacyConsent(false)
        
        // Запрос разрешения на уведомления
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("📱 [OneSignal] User accepted notifications: \(accepted)")
            if accepted {
                // Получаем OneSignal Player ID (userId) - как в старой версии: OneSignal.getDeviceState().then(device => setPushId(device.userId))
                if let deviceState = OneSignal.getDeviceState(),
                   let playerId = deviceState.userId {
                    print("📱 [OneSignal] Player ID: \(playerId)")
                    Task { @MainActor in
                        PushNotificationService.shared.setPushToken(playerId)
                    }
                }
            }
        })
        
        // Подписываемся на изменения Player ID (как в старой версии: OneSignal.addSubscriptionObserver)
        OneSignal.addSubscriptionObserver { state in
            if let playerId = state?.userId {
                print("📱 [OneSignal] Player ID updated: \(playerId)")
                Task { @MainActor in
                    PushNotificationService.shared.setPushToken(playerId)
                }
            }
        }
        
        // Обработчик уведомлений в foreground (как в старой версии: OneSignal.setNotificationWillShowInForegroundHandler)
        OneSignal.setNotificationWillShowInForegroundHandler { notificationReceivedEvent in
            print("📬 [OneSignal] Notification received in foreground")
            // Можно обновить список сообщений (как в старой версии: getMessages())
        }
        
        // Обработчик открытия уведомления (как в старой версии: OneSignal.setNotificationOpenedHandler)
        OneSignal.setNotificationOpenedHandler { notification in
            print("📬 [OneSignal] Notification opened: \(notification)")
            if let userInfo = notification.notification.additionalData {
                PushNotificationService.shared.handleNotification(userInfo)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // OneSignal автоматически обрабатывает device token
        OneSignal.setDeviceToken(deviceToken)
    }
}
```

## Шаг 3: Настройка Capabilities

1. Откройте проект в Xcode
2. Выберите target **LegalTrack**
3. Перейдите в **Signing & Capabilities**
4. Нажмите **+ Capability**
5. Добавьте **Push Notifications**
6. Добавьте **Background Modes** и включите:
   - Remote notifications

## Шаг 4: Настройка Info.plist

Добавьте в `Info.plist` (если используется):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Шаг 5: PushNotificationService (уже реализовано)

`PushNotificationService.swift` уже обновлен с логикой из старой версии:

✅ **Отправка push_id на сервер:**
- Автоматически отправляет OneSignal Player ID на сервер через `/auth/edit-push-uid` (как в старой версии: `setPushId(device.userId)`)
- Сохраняет pending token если пользователь не авторизован
- Отправляет pending token после успешной авторизации

✅ **Обработка уведомлений:**
- Поддерживает типы: `case`, `company`, `message`, `keyword`
- Определяет `is_sou` для дел СОЮ
- Открывает соответствующие экраны через NotificationCenter

✅ **Типы уведомлений (как в старой версии):**
- `type: "case"` → открывает детали дела (с учетом `is_sou`)
- `type: "company"` → открывает детали компании
- `type: "message"` → открывает чат
- `type: "keyword"` → открывает детали ключевого слова

## Шаг 6: Тестирование

1. Запустите приложение на реальном устройстве (push не работают на симуляторе)
2. Разрешите уведомления при запросе
3. Проверьте логи в консоли Xcode:
   - `📱 [Push] Token received: ...`
   - `✅ [Push] Push token sent to server successfully`

## Конфигурация OneSignal

Конфигурация взята из `INFRASTRUCTURE.md` и старой версии приложения:

- **App ID**: `ea4c198c-ce69-4724-bbc4-22528e581180` (из старой версии и INFRASTRUCTURE.md)
- **REST API Key**: `M2IwYWJlNGEtMzEzNi00YjNiLThjZjktYzY3NDhiZmQ4OTk0` (из INFRASTRUCTURE.md)

Эти ключи уже настроены в `AppConstants.OneSignal` в `Constants.swift`.

## Обработка уведомлений

Уведомления обрабатываются в нескольких местах:

1. **OneSignal handlers** (в AppDelegate после раскомментирования):
   - `OneSignal.setNotificationWillShowInForegroundHandler` - когда приложение открыто
   - `OneSignal.setNotificationOpenedHandler` - когда пользователь нажал на уведомление

2. **UNUserNotificationCenterDelegate** (уже работает):
   - `AppDelegate.userNotificationCenter(_:willPresent:)` - когда приложение открыто
   - `AppDelegate.userNotificationCenter(_:didReceive:)` - когда пользователь нажал на уведомление

3. **PushNotificationService.handleNotification**:
   - Парсит `additionalData` из OneSignal (как в старой версии: `notification.notification.additionalData`)
   - Отправляет NotificationCenter события для открытия экранов:
     - `OpenCaseDetail` - для дел (с `caseId` и `isSou`)
     - `OpenCompanyDetail` - для компаний (с `companyId`)
     - `OpenChat` - для сообщений
     - `OpenKeywordDetail` - для ключевых слов (с `keywordId`)

## Формат данных уведомлений (из старой версии)

OneSignal отправляет дополнительные данные в формате:
```json
{
  "custom": {
    "type": "case",
    "id": 12345,
    "is_sou": false
  }
}
```

или

```json
{
  "a": {
    "type": "company",
    "id": 67890
  }
}
```

Поддерживаемые типы:
- `type: "case"` + `id` + `is_sou` (опционально)
- `type: "company"` + `id`
- `type: "message"`
- `type: "keyword"` + `id`

