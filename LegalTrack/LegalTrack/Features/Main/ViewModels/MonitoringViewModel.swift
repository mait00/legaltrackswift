//
//  MonitoringViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation
import Combine
import SwiftUI

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

    // Deep cache (case details) prefetch state.
    @Published private(set) var isPrefetchingCaseDetails = false
    @Published private(set) var prefetchDoneCount: Int = 0
    @Published private(set) var prefetchTotalCount: Int = 0
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var prefetchTask: Task<Void, Never>?
    
    init() {
        // Следим за состоянием сети
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if !isConnected {
                    self?.prefetchTask?.cancel()
                    self?.isPrefetchingCaseDetails = false
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

        NotificationCenter.default.publisher(for: .monitoringCasesDidChange)
            .sink { [weak self] _ in
                Task { await self?.loadCases() }
            }
            .store(in: &cancellables)
    }
    
    /// Очистить все данные (при смене пользователя)
    func clearData() {
        prefetchTask?.cancel()
        isPrefetchingCaseDetails = false
        prefetchDoneCount = 0
        prefetchTotalCount = 0
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

            // Deep cache: prefetch details for all cases so detail screens are available offline.
            startPrefetchCaseDetails(for: cases)
            
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

    private func startPrefetchCaseDetails(for cases: [LegalCase]) {
        prefetchTask?.cancel()

        // Don't prefetch when offline or when list is empty.
        guard networkMonitor.isConnected else { return }
        let api = APIService.shared
        let cache = CacheManager.shared
        let caseIds = cases.map { $0.id }
        guard !caseIds.isEmpty else { return }

        prefetchTask = Task { [weak self] in
            guard let self else { return }

            let missing = await cacheManager.missingCaseDetailIds(for: caseIds)
            await MainActor.run {
                self.prefetchTotalCount = missing.count
                self.prefetchDoneCount = 0
                self.isPrefetchingCaseDetails = !missing.isEmpty
            }
            guard !missing.isEmpty else { return }

            // Limit concurrency to avoid spamming the backend.
            let concurrency = 3
            var iterator = missing.makeIterator()
            let worker = CaseDetailPrefetchWorker(api: api, cache: cache)

            await withTaskGroup(of: Void.self) { group in
                func addNext() {
                    guard !Task.isCancelled else { return }
                    guard let id = iterator.next() else { return }
                    group.addTask {
                        await worker.fetchAndCache(caseId: id)
                    }
                }

                for _ in 0..<concurrency { addNext() }

                while await group.next() != nil {
                    await MainActor.run {
                        self.prefetchDoneCount += 1
                    }
                    addNext()
                }
            }

            await MainActor.run {
                self.isPrefetchingCaseDetails = false
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
            let status = response.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let message = response.message?.lowercased() ?? ""
            let isSuccess = response.success == true
                || status == "success"
                || message.contains("успех")
                || (message.contains("подписк") && message.contains("удален"))

            if isSuccess {
                if let idx = cases.firstIndex(where: { $0.id == id }) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        _ = cases.remove(at: idx)
                    }
                    await cacheManager.saveCasesAsync(cases)
                }
                NotificationCenter.default.post(name: .monitoringCasesDidChange, object: nil)
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

private actor CaseDetailPrefetchWorker {
    private let api: APIService
    private let cache: CacheManager

    init(api: APIService, cache: CacheManager) {
        self.api = api
        self.cache = cache
    }

    func fetchAndCache(caseId: Int) async {
        do {
            let response: CaseDetailResponse = try await api.request(
                endpoint: APIEndpoint.detailCase(id: caseId).path,
                method: .get
            )
            if let data = response.data {
                await cache.saveCaseDetailAsync(data, for: caseId)
            }
        } catch {
            // Silent by design.
        }
    }
}
