//
//  MonitoringViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation
import Combine

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var cases: [LegalCase] = []
    @Published var companies: [Company] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    @Published var lastSyncTime: Date?
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Следим за состоянием сети
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if !isConnected {
                    // Если пропало соединение, загружаем из кэша
                    self?.loadFromCache()
                }
            }
            .store(in: &cancellables)
        
        // Загружаем время последней синхронизации
        lastSyncTime = cacheManager.getLastSyncTime()
        
        // Подписываемся на уведомления о смене пользователя
        NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))
            .sink { [weak self] _ in
                self?.clearData()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))
            .sink { [weak self] _ in
                self?.clearData()
            }
            .store(in: &cancellables)
    }
    
    /// Очистить все данные (при смене пользователя)
    func clearData() {
        cases = []
        companies = []
        errorMessage = nil
        lastSyncTime = nil
        isLoading = false
        print("🗑️ [MonitoringViewModel] Data cleared on user change")
    }
    
    /// Загрузить дела (с поддержкой офлайн)
    func loadCases() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if loadFromCache() {
            print("📦 [Monitoring] Showing cached cases first")
            // Не устанавливаем isLoading = false, чтобы показать индикатор обновления
        } else {
            isLoading = true
        }
        
        // Если офлайн — только кэш
        if !networkMonitor.isConnected {
            isLoading = false
            return
        }
        
        print("📋 Loading cases from: \(APIEndpoint.getSubscriptions.path)")
        
        do {
            let response: SubscriptionsResponse = try await apiService.request(
                endpoint: APIEndpoint.getSubscriptions.path,
                method: .get
            )
            
            print("📋 ✅ Received \(response.cases.count) cases")
            
            // Обновляем данные
            cases = response.cases
            companies = response.companies
            
            // Кэшируем результат
            cacheManager.saveCases(cases)
            cacheManager.saveCompanies(companies)
            lastSyncTime = Date()
            
            print("📋 ✅ Final cases count: \(cases.count)")
            
            isLoading = false
        } catch {
            isLoading = false
            print("❌ Error loading cases: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if cases.isEmpty {
                if loadFromCache() {
                    errorMessage = nil // Не показываем ошибку если есть кэш
                } else {
                    errorMessage = error.localizedDescription
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
        var loaded = false
        
        // Загружаем дела
        if let cachedCases = cacheManager.loadCachedCases() {
            cases = cachedCases
            lastSyncTime = cacheManager.getLastSyncTime()
            print("📦 Loaded \(cachedCases.count) cases from cache")
            loaded = true
        }
        
        // Загружаем компании
        if let cachedCompanies = cacheManager.loadCachedCompanies() {
            companies = cachedCompanies
            print("📦 Loaded \(cachedCompanies.count) companies from cache")
            loaded = true
        }
        
        return loaded
    }
    
    /// Удалить дело из мониторинга (с поддержкой старого GET эндпоинта)
    func deleteCase(_ legalCase: LegalCase) async {
        struct DeleteResponse: Codable { let success: Bool?; let status: String?; let message: String? }
        let id = legalCase.id
        do {
            let endpoint = "/subs/delete?id=\(id)&type=case"
            let response: DeleteResponse = try await apiService.request(endpoint: endpoint, method: .get)
            if response.success == true || response.status?.lowercased() == "success" {
                if let idx = cases.firstIndex(where: { $0.id == id }) {
                    cases.remove(at: idx)
                    cacheManager.saveCases(cases)
                }
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "Не удалось удалить дело"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

