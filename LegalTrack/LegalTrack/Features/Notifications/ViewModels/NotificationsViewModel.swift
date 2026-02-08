//
//  NotificationsViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = [] {
        didSet {
            recalculateDerivedState()
        }
    }
    @Published private(set) var groupedNotifications: [(date: String, notifications: [AppNotification])] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    // Пагинация
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    var hasMorePages: Bool {
        currentPage < totalPages
    }
    
    init() {
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
        notifications = []
        unreadCount = 0
        currentPage = 1
        totalPages = 1
        errorMessage = nil
        isLoading = false
        isLoadingMore = false
        print("🗑️ [NotificationsViewModel] Data cleared on user change")
    }
    
    /// Загрузить уведомления (первая страница)
    func loadNotifications() async {
        errorMessage = nil
        currentPage = 1
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if await loadFromCache(page: 1) {
            print("📦 [Notifications] Showing cached notifications first")
        } else {
            isLoading = true
        }
        
        // Если офлайн — только кэш
        if !networkMonitor.isConnected {
            isLoading = false
            return
        }
        
        do {
            let data = try await apiService.requestData(
                endpoint: "\(APIEndpoint.getNotifications.path)?page=1",
                method: .get
            )
            
            // Используем кастомный декодер без convertFromSnakeCase
            let decoder = JSONDecoder()
            let response = try decoder.decode(NotificationsResponse.self, from: data)
            
            print("📬 [Notifications] Response received: \(response.data.count) items, page \(response.page ?? 1)/\(response.totalPages ?? 1)")
            
            // Обновляем данные
            notifications = response.data
            totalPages = response.totalPages ?? 1
            currentPage = response.page ?? 1
            
            // Кэшируем результат
            await cacheManager.saveNotificationsAsync(notifications, page: 1)
            
            isLoading = false
            errorMessage = nil
            print("✅ [Notifications] Loaded \(notifications.count) notifications successfully")
        } catch is CancellationError {
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            print("❌ [Notifications] Error loading notifications: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if notifications.isEmpty {
                if await loadFromCache(page: 1) {
                    errorMessage = nil
                    print("📦 [Notifications] Using cached notifications after error")
                } else {
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription ?? error.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    print("❌ [Notifications] No cache available, showing error: \(errorMessage ?? "Unknown")")
                }
            } else {
                // Если кэш уже показан - не показываем ошибку
                errorMessage = nil
                print("📦 [Notifications] Keeping cached notifications, error ignored")
            }
        }
    }
    
    /// Загрузить из кэша
    @discardableResult
    private func loadFromCache(page: Int) async -> Bool {
        if let cachedNotifications = await cacheManager.loadCachedNotificationsAsync(page: page) {
            if page == 1 {
                notifications = cachedNotifications
            } else {
                notifications.append(contentsOf: cachedNotifications)
            }
            print("📦 Loaded \(cachedNotifications.count) notifications (page \(page)) from cache")
            return true
        }
        return false
    }
    
    /// Загрузить следующую страницу
    func loadMoreIfNeeded(currentItem: AppNotification) async {
        // Проверяем, что это последний элемент и есть ещё страницы
        guard let lastItem = notifications.last,
              currentItem.id == lastItem.id && currentItem.meta == lastItem.meta,
              hasMorePages,
              !isLoadingMore else {
            return
        }
        
        await loadMore()
    }
    
    /// Загрузить ещё уведомления
    private func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        do {
            let data = try await apiService.requestData(
                endpoint: "\(APIEndpoint.getNotifications.path)?page=\(nextPage)",
                method: .get
            )
            
            // Используем кастомный декодер без convertFromSnakeCase
            let decoder = JSONDecoder()
            let response = try decoder.decode(NotificationsResponse.self, from: data)
            
            print("📬 [Notifications] Loaded page \(nextPage): \(response.data.count) items")
            notifications.append(contentsOf: response.data)
            totalPages = response.totalPages ?? totalPages
            currentPage = response.page ?? nextPage
            await cacheManager.saveNotificationsAsync(response.data, page: nextPage)
            isLoadingMore = false
            print("✅ [Notifications] Total notifications: \(notifications.count)")
        } catch is CancellationError {
            isLoadingMore = false
        } catch {
            isLoadingMore = false
            print("❌ [Notifications] Error loading more notifications: \(error)")
        }
    }
    
    /// Отметить уведомление как прочитанное
    func markAsRead(_ notification: AppNotification) async {
        guard let index = notifications.firstIndex(where: { 
            $0.id == notification.id && $0.caseId == notification.caseId && $0.meta == notification.meta 
        }), !notification.isRead else { return }
        
        // Создаём обновлённое уведомление
        var updatedNotification = notification
        updatedNotification.isRead = true
        
        notifications[index] = updatedNotification
    }
    
    /// Отметить все как прочитанные
    func markAllAsRead() async {
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
    }
    
    /// Получить иконку для типа уведомления
    func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .company:
            return "building.2.fill"
        case .caseType:
            return "doc.text.fill"
        }
    }
    
    /// Получить цвет для типа уведомления
    func colorForType(_ type: NotificationType) -> String {
        switch type {
        case .company:
            return "purple"
        case .caseType:
            return "blue"
        }
    }

    private func recalculateDerivedState() {
        unreadCount = notifications.reduce(into: 0) { count, notification in
            if !notification.isRead { count += 1 }
        }

        let grouped = Dictionary(grouping: notifications) { $0.meta }
        groupedNotifications = grouped.map { (date: $0.key, notifications: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
