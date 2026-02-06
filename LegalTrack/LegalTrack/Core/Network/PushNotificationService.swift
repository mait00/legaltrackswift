//
//  PushNotificationService.swift
//  LegalTrack
//
//  Сервис для работы с push уведомлениями через OneSignal
//

import Foundation
import UserNotifications

/// Сервис для работы с push уведомлениями
@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    private let oneSignalAppId = "ea4c198c-ce69-4724-bbc4-22528e581180"
    private let apiService = APIService.shared
    
    @Published var pushToken: String?
    @Published var isSubscribed: Bool = false
    
    private override init() {
        super.init()
    }
    
    /// Инициализация OneSignal (вызывается после установки SDK)
    func initialize() {
        // OneSignal SDK будет инициализирован через AppDelegate
        // Этот метод вызывается для настройки после установки SDK
        requestNotificationPermission()
        
        // Пытаемся получить Player ID из UserDefaults (OneSignal SDK 5.0 сохраняет его там)
        checkForPlayerID()
    }
    
    /// Проверить наличие Player ID в UserDefaults (OneSignal SDK 5.0 сохраняет его там)
    func checkForPlayerID() {
        // OneSignal SDK 5.0 сохраняет Player ID в UserDefaults с ключом "ONESIGNAL_USERID"
        if let playerId = UserDefaults.standard.string(forKey: "ONESIGNAL_USERID"),
           !playerId.isEmpty {
            print("📱 [OneSignal] Found Player ID in UserDefaults: \(playerId)")
            setPushToken(playerId)
        } else {
            // Также проверяем другие возможные ключи
            let possibleKeys = ["OneSignal_UserID", "OneSignalPlayerId", "ONESIGNAL_PLAYER_ID"]
            for key in possibleKeys {
                if let playerId = UserDefaults.standard.string(forKey: key),
                   !playerId.isEmpty {
                    print("📱 [OneSignal] Found Player ID with key '\(key)': \(playerId)")
                    setPushToken(playerId)
                    return
                }
            }
            print("ℹ️ [OneSignal] Player ID not found yet, will check after push registration")
        }
    }
    
    /// Запрос разрешения на уведомления
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ [Push] Notification permission granted")
                DispatchQueue.main.async {
                    self.isSubscribed = true
                }
            } else {
                print("❌ [Push] Notification permission denied")
                DispatchQueue.main.async {
                    self.isSubscribed = false
                }
            }
            
            if let error = error {
                print("❌ [Push] Permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Установить push token (вызывается из OneSignal SDK)
    /// token - это OneSignal Player ID (userId), как в старой версии: OneSignal.getDeviceState().then(device => setPushId(device.userId))
    func setPushToken(_ token: String) {
        self.pushToken = token
        print("📱 [Push] OneSignal Player ID received: \(token)")
        
        // Отправляем push_id на сервер через /auth/edit-push-uid
        sendPushTokenToServer(token)
    }
    
    /// Отправить pending push token после авторизации
    func sendPendingPushToken() {
        if let pendingToken = UserDefaultsManager.shared.getString(forKey: "pending_push_token"),
           !pendingToken.isEmpty {
            print("📤 [Push] Sending pending push token after login")
            sendPushTokenToServer(pendingToken)
            UserDefaultsManager.shared.remove(forKey: "pending_push_token")
        }
    }
    
    /// Отправить push token на сервер (как в старой версии через /auth/edit-push-uid)
    func sendPushTokenToServer(_ token: String) {
        // Проверяем, что пользователь авторизован
        guard let authToken = KeychainManager.shared.get(forKey: AppConstants.StorageKeys.authToken),
              !authToken.isEmpty else {
            print("⚠️ [Push] User not authenticated, token will be sent after login")
            // Сохраняем токен для отправки после авторизации
            UserDefaultsManager.shared.saveString(token, forKey: "pending_push_token")
            return
        }
        
        Task {
            do {
                // Отправляем push_id на сервер через эндпоинт /auth/edit-push-uid
                // Как в старой версии: setPushId(device.userId)
                let endpoint = APIEndpoint.editPushUID(uid: token)
                guard let requestBody = endpoint.body as? EditPushUIDRequest else {
                    print("❌ [Push] Failed to create request body")
                    return
                }
                
                struct SimpleResponse: Codable {
                    let success: Bool?
                    let status: String?
                    let message: String?
                }
                
                let _: SimpleResponse = try await apiService.request(
                    endpoint: endpoint.path,
                    method: endpoint.method,
                    body: requestBody
                )
                
                print("✅ [Push] Push token sent to server successfully: \(token)")
            } catch {
                print("❌ [Push] Failed to send token to server: \(error)")
            }
        }
    }
    
    /// Обработка полученного push уведомления (как в старой версии)
    nonisolated func handleNotification(_ userInfo: [AnyHashable: Any]) {
        print("📬 [Push] Received notification: \(userInfo)")
        
        // OneSignal отправляет дополнительные данные в userInfo["custom"] или userInfo["a"]
        // Формат как в старой версии: notification.notification.additionalData
        var notificationType: String?
        var caseId: Int?
        var companyId: Int?
        var keywordId: Int?
        var isSou: Bool?
        
        // Проверяем формат OneSignal: userInfo["custom"] или userInfo["a"]
        var additionalData: [String: Any]?
        
        if let custom = userInfo["custom"] as? [String: Any] {
            additionalData = custom
        } else if let a = userInfo["a"] as? [String: Any] {
            additionalData = a
        } else if let additional = userInfo["additionalData"] as? [String: Any] {
            additionalData = additional
        }
        
        // Извлекаем данные из additionalData (как в старой версии)
        if let data = additionalData {
            notificationType = data["type"] as? String
            caseId = data["id"] as? Int ?? (data["case_id"] as? Int)
            companyId = data["company_id"] as? Int
            keywordId = data["keyword_id"] as? Int
            if let isSouValue = data["is_sou"] {
                isSou = (isSouValue as? Bool) ?? ((isSouValue as? Int) == 1) ?? ((isSouValue as? String) == "true")
            }
        }
        
        // Также проверяем прямой формат в userInfo
        if notificationType == nil {
            notificationType = userInfo["type"] as? String
        }
        if caseId == nil {
            caseId = userInfo["id"] as? Int ?? (userInfo["case_id"] as? Int)
        }
        if companyId == nil {
            companyId = userInfo["company_id"] as? Int
        }
        if keywordId == nil {
            keywordId = userInfo["keyword_id"] as? Int
        }
        
        // Обработка по типу уведомления (как в старой версии)
        guard let type = notificationType else {
            // Если тип не указан, пытаемся определить по наличию ID
            if let caseId = caseId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenCaseDetail"),
                    object: nil,
                    userInfo: ["caseId": caseId, "isSou": isSou ?? false]
                )
            } else if let companyId = companyId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenCompanyDetail"),
                    object: nil,
                    userInfo: ["companyId": companyId]
                )
            }
            return
        }
        
        switch type {
        case "case":
            if let caseId = caseId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenCaseDetail"),
                    object: nil,
                    userInfo: ["caseId": caseId, "isSou": isSou ?? false]
                )
            }
            
        case "company":
            if let companyId = companyId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenCompanyDetail"),
                    object: nil,
                    userInfo: ["companyId": companyId]
                )
            }
            
        case "message":
            // Открываем чат
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChat"),
                object: nil
            )
            
        case "keyword":
            if let keywordId = keywordId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenKeywordDetail"),
                    object: nil,
                    userInfo: ["keywordId": keywordId]
                )
            }
            
        default:
            print("⚠️ [Push] Unknown notification type: \(type)")
        }
    }
    
    /// Отписаться от уведомлений
    func unsubscribe() {
        isSubscribed = false
        pushToken = nil
        print("📴 [Push] Unsubscribed from notifications")
    }
}

