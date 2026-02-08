//
//  CaseDetailViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// ViewModel для детальной страницы дела
@MainActor
final class CaseDetailViewModel: ObservableObject {
    @Published private(set) var caseDetail: NormalizedCaseDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFromCache = false
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    /// Загрузить детали дела (с поддержкой офлайн)
    func loadCaseDetail(caseId: Int) async {
        errorMessage = nil
        isFromCache = false
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if await loadFromCache(caseId: caseId) {
            print("📦 [CaseDetail] Showing cached data first")
            // Не устанавливаем isLoading = false, чтобы показать индикатор обновления
        } else {
            isLoading = true
        }
        
        // Если офлайн — только кэш
        if !networkMonitor.isConnected {
            isLoading = false
            return
        }
        
        let endpoint = APIEndpoint.detailCase(id: caseId).path
        print("📋 [CaseDetail] Loading case detail for id: \(caseId)")
        
        do {
            let response: CaseDetailResponse = try await apiService.request(
                endpoint: endpoint,
                method: .get
            )
            
            print("📋 [CaseDetail] Response received")
            
            if let data = response.data {
                // Кэшируем данные
                await cacheManager.saveCaseDetailAsync(data, for: caseId)
                
                // Нормализуем данные
                let normalized = NormalizedCaseDetail(from: data)
                print("📋 [CaseDetail] Normalized: number=\(normalized.number), instances=\(normalized.instances.count)")
                
                // Обновляем данные (даже если был кэш)
                self.caseDetail = normalized
                self.isFromCache = false
            } else {
                print("❌ [CaseDetail] No data in response")
                // Если кэша не было - показываем ошибку
                if caseDetail == nil {
                    errorMessage = "Данные не найдены"
                }
            }
            
            isLoading = false
        } catch is CancellationError {
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            print("❌ [CaseDetail] Error: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if caseDetail == nil {
                if await loadFromCache(caseId: caseId) {
                    errorMessage = nil
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
    private func loadFromCache(caseId: Int) async -> Bool {
        if let cachedData = await cacheManager.loadCachedCaseDetailAsync(for: caseId) {
            let normalized = NormalizedCaseDetail(from: cachedData)
            self.caseDetail = normalized
            self.isFromCache = true
            print("📦 [CaseDetail] Loaded from cache")
            return true
        }
        return false
    }
}
