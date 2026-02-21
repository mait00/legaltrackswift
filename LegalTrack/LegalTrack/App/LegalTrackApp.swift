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
    @Published private(set) var userProfile: UserProfile?
    /// Tariff status from `/api/user-tarif` (more reliable than profile flag on some backends).
    @Published private(set) var tariffActive: Bool?
    
    private let keychainManager = KeychainManager.shared
    private let userDefaultsManager = UserDefaultsManager.shared
    private let apiService = APIService.shared
    
    init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserProfileShouldRefresh"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.loadUserProfile() }
        }
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
        do {
            let response: UserProfileResponse = try await apiService.request(
                endpoint: APIEndpoint.getProfile.path,
                method: .get
            )
            userProfile = response.data

            // Keep `currentUser` best-effort in sync for existing UI uses.
            if let p = response.data,
               let id = p.id,
               let first = p.firstName,
               let last = p.lastName,
               let email = p.email,
               let phone = p.phone {
                currentUser = User(id: id, firstName: first, lastName: last, email: email, phone: phone, type: p.type)
            }

            // Best-effort: also fetch tariff status.
            await loadTariffStatus()
            print("👤 [AppState] Profile loaded. profileTarifActive=\(userProfile?.isTarifActive ?? false), userTarifActive=\(tariffActive ?? false)")
        } catch {
            print("❌ [AppState] Failed to load profile: \(error)")
        }
    }

    private func loadTariffStatus() async {
        do {
            let response: TariffsResponse = try await apiService.request(
                endpoint: APIEndpoint.getUserTarif.path,
                method: .get
            )
            tariffActive = response.data?.active
        } catch {
            // Keep previous value; don't fail profile load because of tariff endpoint.
            tariffActive = tariffActive
        }
    }

    /// Single source of truth for feature gating in UI.
    var isTariffActiveEffective: Bool {
        if let t = tariffActive { return t }
        return userProfile?.isTarifActive ?? false
    }
    
    func authenticate(with token: String) {
        _ = keychainManager.save(token, forKey: AppConstants.StorageKeys.authToken)
        apiService.setToken(token)
        isAuthenticated = true
        
        // Очищаем кеш перед входом нового пользователя, чтобы не показывать старые данные
        Task {
            await CacheManager.shared.clearAllCacheAsync()
            print("🗑️ [AppState] Cache cleared on user login")
        }
        
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
        userProfile = nil
        apiService.setToken(nil)
        
        // Очищаем кеш при выходе пользователя
        Task {
            await CacheManager.shared.clearAllCacheAsync()
            print("🗑️ [AppState] Cache cleared on user logout")
        }
        
        // Уведомляем о выходе пользователя (для очистки данных в ViewModels)
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        
        // Вынесено в фон: может быть ощутимо на больших доменах UserDefaults/Keychain.
        Task.detached(priority: .utility) { [keychainManager, userDefaultsManager] in
            keychainManager.clearAll()
            userDefaultsManager.clearAll()
        }
    }

    /// Public refresh hook for UI (tariffs/profile screens).
    func refreshUserProfile() {
        Task { await loadUserProfile() }
    }
}

/// Главный контейнер приложения
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        #if DEBUG
        if let urlString = ProcessInfo.processInfo.environment["LT_DEBUG_PDF_URL"],
           let url = URL(string: urlString) {
            SafariPDFScreen(url: url, title: "Debug PDF")
        } else {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
        }
        #else
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        #endif
    }
}
