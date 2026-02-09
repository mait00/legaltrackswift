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

    private static let iso8601WithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    /// Загрузить компании
    func loadCompanies() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if await loadFromCache() {
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
            companies = sortCompanies(response.companies)
            
            // Кэшируем результат
            await cacheManager.saveCompaniesAsync(companies)
            
            print("🏢 ✅ Final companies count: \(companies.count)")
            
            if companies.isEmpty {
                print("⚠️ WARNING: Companies array is empty after parsing!")
            } else {
                print("🏢 First company: \(companies.first?.name ?? "N/A")")
            }
            
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            print("❌ Error loading companies: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if companies.isEmpty {
                if await loadFromCache() {
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
    private func loadFromCache() async -> Bool {
        if let cachedCompanies = await cacheManager.loadCachedCompaniesAsync() {
            companies = sortCompanies(cachedCompanies)
            print("📦 Loaded \(cachedCompanies.count) companies from cache")
            return true
        }
        return false
    }

    private func sortCompanies(_ items: [Company]) -> [Company] {
        items.sorted { a, b in
            let da = createdAtDate(a.createdAt)
            let db = createdAtDate(b.createdAt)
            if da != db { return da > db }
            // Fallback: id у API монотонно растет, как минимум стабилизирует порядок.
            return a.id > b.id
        }
    }

    private func createdAtDate(_ s: String?) -> Date {
        guard let s else { return .distantPast }
        if let d = Self.iso8601WithFrac.date(from: s) { return d }
        if let d = Self.iso8601.date(from: s) { return d }
        return .distantPast
    }
}
