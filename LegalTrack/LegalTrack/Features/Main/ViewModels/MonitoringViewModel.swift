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
    @Published var cases: [LegalCase] = [] {
        didSet { recomputeFilteredCases() }
    }
    @Published var companies: [Company] = []
    @Published var selectedFilter: CaseFilter = .all {
        didSet { recomputeFilteredCases() }
    }
    @Published var searchText: String = "" {
        didSet { recomputeFilteredCases() }
    }
    @Published private(set) var filteredCases: [LegalCase] = []
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
                    Task { await self?.loadFromCache() }
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
        filteredCases = []
        errorMessage = nil
        lastSyncTime = nil
        isLoading = false
        print("🗑️ [MonitoringViewModel] Data cleared on user change")
    }
    
    /// Загрузить дела (с поддержкой офлайн)
    func loadCases() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if await loadFromCache() {
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
            await cacheManager.saveCasesAsync(cases)
            await cacheManager.saveCompaniesAsync(companies)
            lastSyncTime = Date()
            
            print("📋 ✅ Final cases count: \(cases.count)")
            
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            print("❌ Error loading cases: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if cases.isEmpty {
                if await loadFromCache() {
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
    private func loadFromCache() async -> Bool {
        var loaded = false
        
        // Загружаем дела
        if let cachedCases = await cacheManager.loadCachedCasesAsync() {
            cases = cachedCases
            lastSyncTime = cacheManager.getLastSyncTime()
            print("📦 Loaded \(cachedCases.count) cases from cache")
            loaded = true
        }
        
        // Загружаем компании
        if let cachedCompanies = await cacheManager.loadCachedCompaniesAsync() {
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
                    await cacheManager.saveCasesAsync(cases)
                }
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "Не удалось удалить дело"
                }
            }
        } catch is CancellationError {
            return
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func recomputeFilteredCases() {
        var result = cases

        switch selectedFilter {
        case .all:
            break
        case .arbitration:
            result = result.filter { $0.isSou != true }
        case .general:
            result = result.filter { $0.isSou == true }
        }

        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !normalizedQuery.isEmpty {
            result = result.filter { legalCase in
                if let value = legalCase.value?.lowercased(), value.contains(normalizedQuery) {
                    return true
                }
                if let name = legalCase.name?.lowercased(), name.contains(normalizedQuery) {
                    return true
                }
                if let sidePl = legalCase.sidePl?.lowercased(), sidePl.contains(normalizedQuery) {
                    return true
                }
                return false
            }
        }

        result.sort { lhs, rhs in
            let lhsLoading = lhs.status?.lowercased() == "loading"
            let rhsLoading = rhs.status?.lowercased() == "loading"
            if lhsLoading != rhsLoading { return lhsLoading && !rhsLoading }
            let lhsNew = lhs.new ?? 0
            let rhsNew = rhs.new ?? 0
            if lhsNew != rhsNew { return lhsNew > rhsNew }
            return lhs.id > rhs.id
        }

        filteredCases = result
    }
}
