//
//  CompaniesViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// ViewModel для компаний
@MainActor
final class CompaniesViewModel: ObservableObject {
    @Published private(set) var companies: [Company] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    /// Загрузить компании
    func loadCompanies() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if loadFromCache() {
            print("📦 [Companies] Showing cached companies first")
        } else {
            isLoading = true
        }
        
        // Если офлайн — только кэш
        if !networkMonitor.isConnected {
            isLoading = false
            return
        }
        
        print("🏢 Loading companies from: \(APIEndpoint.getSubscriptions.path)")
        
        do {
            let response: SubscriptionsResponse = try await apiService.request(
                endpoint: APIEndpoint.getSubscriptions.path,
                method: .get
            )
            
            print("🏢 Subscriptions response received")
            print("🏢 Companies count: \(response.companies.count)")
            
            // Обновляем данные
            companies = response.companies
            
            // Кэшируем результат
            cacheManager.saveCompanies(companies)
            
            print("🏢 ✅ Final companies count: \(companies.count)")
            
            if companies.isEmpty {
                print("⚠️ WARNING: Companies array is empty after parsing!")
            } else {
                print("🏢 First company: \(companies.first?.name ?? "N/A")")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            print("❌ Error loading companies: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if companies.isEmpty {
                if loadFromCache() {
                    errorMessage = nil
                } else {
                    errorMessage = error.localizedDescription
                    if let apiError = error as? APIError {
                        print("❌ API Error details: \(apiError)")
                    }
                }
            } else {
                // Если кэш уже показан - не показываем ошибку
                errorMessage = nil
            }
        }
    }
    
    /// Загрузить из кэша
    @discardableResult
    private func loadFromCache() -> Bool {
        if let cachedCompanies = cacheManager.loadCachedCompanies() {
            companies = cachedCompanies
            print("📦 Loaded \(cachedCompanies.count) companies from cache")
            return true
        }
        return false
    }
}


