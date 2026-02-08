//
//  AppDelegate.swift
//  LegalTrack
//
//  AppDelegate для обработки push уведомлений
//

import UIKit
import UserNotifications
import OneSignalFramework

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, OSPushSubscriptionObserver {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Настройка уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        OneSignal.Debug.setLogLevel(.LL_NONE)
        
        // Configure OneSignal SDK 5.x
        // Set your OneSignal App ID
        OneSignal.initialize(AppConstants.OneSignal.appId)
        
        // Observe push subscription changes to get the Player ID (userId)
        OneSignal.User.pushSubscription.addObserver(self)
        PushNotificationService.shared.checkForPlayerID()
        
        // Prompt user for notification permission and register for APNs
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ [Push] Permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    OneSignal.User.pushSubscription.optIn()
                    print("✅ [Push] Permission granted, registered for remote notifications")
                } else {
                    print("⚠️ [Push] Permission not granted")
                }
                self.logOneSignalState(context: "didFinishLaunching.requestAuthorization")
            }
        }
        
        print("✅ [OneSignal] SDK initialized with App ID: \(AppConstants.OneSignal.appId)")
        logOneSignalState(context: "didFinishLaunching.afterInitialize")
        
        // Обработка уведомлений происходит через UNUserNotificationCenterDelegate методы ниже
        // Player ID будет отправлен на сервер через PushNotificationService после получения
        
        return true
    }
    
    // MARK: - Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // OneSignal автоматически обрабатывает device token через initWithLaunchOptions
        
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 [Push] Device token registered: \(token)")
        
        // Явно передаем APNs token в OneSignal для надежности интеграции на физическом устройстве
        OSNotificationsManager.didRegister(forRemoteNotifications: application, deviceToken: deviceToken)
        
        // Provide APNs token to OneSignal (SDK 5 handles automatically, this is safe)
        // OneSignal.SetAPNSToken(deviceToken)  <-- This line removed
        
        // OneSignal SDK 5.0 автоматически получает Player ID после регистрации
        // Player ID будет отправлен на сервер через PushNotificationService
        // когда он станет доступен (через обработчики уведомлений или через периодическую проверку)
        
        // Пытаемся получить Player ID из UserDefaults после регистрации токена
        Task { @MainActor in
            // OneSignal SDK 5.0 сохраняет Player ID в UserDefaults после регистрации
            // Проверяем через небольшую задержку, чтобы SDK успел сохранить
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
            
            // Проверяем Player ID через PushNotificationService
            PushNotificationService.shared.checkForPlayerID()
            self.logOneSignalState(context: "didRegisterForRemoteNotifications +2s")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        OSNotificationsManager.handleDidFailRegister(forRemoteNotification: error)
        print("❌ [Push] Failed to register: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Уведомление получено когда приложение открыто
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        PushNotificationService.shared.handleNotification(userInfo)
        
        // Показываем уведомление даже когда приложение открыто
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Пользователь нажал на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        PushNotificationService.shared.handleNotification(userInfo)
        
        completionHandler()
    }
    
    // MARK: - OneSignal OSPushSubscriptionObserver
    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        // Retrieve the current push subscription and Player ID
        let subscription = OneSignal.User.pushSubscription
        print("ℹ️ [OneSignal] Subscription changed: id=\(subscription.id ?? "nil"), token=\(subscription.token ?? "nil"), optedIn=\(subscription.optedIn)")
        if let userId = subscription.id, !userId.isEmpty {
            print("📱 [OneSignal] Player ID updated: \(userId)")
            Task { @MainActor in
                PushNotificationService.shared.setPushToken(userId)
            }
        } else {
            print("ℹ️ [OneSignal] Player ID not available yet")
        }
    }
    
    private func logOneSignalState(context: String) {
        let subscription = OneSignal.User.pushSubscription
        print("ℹ️ [OneSignal][\(context)] permission=\(OneSignal.Notifications.permission), canRequest=\(OneSignal.Notifications.canRequestPermission), optedIn=\(subscription.optedIn), subscriptionId=\(subscription.id ?? "nil"), token=\(subscription.token ?? "nil"), onesignalId=\(OneSignal.User.onesignalId ?? "nil")")
    }
}
