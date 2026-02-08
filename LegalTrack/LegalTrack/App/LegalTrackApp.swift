//
//  LegalTrackApp.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

@main
struct LegalTrackApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

/// Состояние приложения
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    
    private let keychainManager = KeychainManager.shared
    private let userDefaultsManager = UserDefaultsManager.shared
    private let apiService = APIService.shared
    
    init() {
        checkAuthentication()
    }
    
    private func checkAuthentication() {
        if let token = keychainManager.get(forKey: AppConstants.StorageKeys.authToken),
           !token.isEmpty {
            apiService.setToken(token)
            isAuthenticated = true
            Task {
                await loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() async {
        // TODO: Загрузить профиль пользователя через API
    }
    
    func authenticate(with token: String) {
        _ = keychainManager.save(token, forKey: AppConstants.StorageKeys.authToken)
        apiService.setToken(token)
        isAuthenticated = true
        
        // Очищаем кеш перед входом нового пользователя, чтобы не показывать старые данные
        CacheManager.shared.clearAllCache()
        print("🗑️ [AppState] Cache cleared on user login")
        
        // Уведомляем о входе пользователя (для очистки данных в ViewModels)
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        
        // Отправляем pending push token если есть (как в старой версии)
        PushNotificationService.shared.sendPendingPushToken()
        
        Task {
            await loadUserProfile()
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        apiService.setToken(nil)
        
        // Очищаем кеш при выходе пользователя
        CacheManager.shared.clearAllCache()
        print("🗑️ [AppState] Cache cleared on user logout")
        
        // Уведомляем о выходе пользователя (для очистки данных в ViewModels)
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        
        keychainManager.clearAll()
        userDefaultsManager.clearAll()
    }
}

/// Главный контейнер приложения
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}
