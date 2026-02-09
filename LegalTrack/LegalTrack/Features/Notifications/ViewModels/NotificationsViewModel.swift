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
    struct NotificationGroup: Identifiable {
        let id: Date
        let title: String
        let notifications: [AppNotification]
    }

    @Published var notifications: [AppNotification] = [] {
        didSet { recalculateDerivedState() }
    }
    @Published private(set) var groupedNotifications: [NotificationGroup] = []
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
    private var readKeys: Set<String>
    private let calendar = Calendar.current

    private static let metaISO8601WithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let metaISO8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let metaFormatters: [DateFormatter] = {
        func make(_ format: String, locale: Locale = Locale(identifier: "en_US_POSIX")) -> DateFormatter {
            let f = DateFormatter()
            f.locale = locale
            f.calendar = Calendar(identifier: .gregorian)
            f.timeZone = .current
            f.isLenient = false
            f.dateFormat = format
            // Для форматов с 2-значным годом (yy): интерпретируем 00-99 как 2000-2099.
            if #available(iOS 15.0, *) {
                f.twoDigitStartDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1))
            }
            return f
        }
        return [
            make("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            make("yyyy-MM-dd'T'HH:mm:ssZ"),
            make("yyyy-MM-dd'T'HH:mm:ss"),
            make("yyyy-MM-dd HH:mm:ss"),
            make("yyyy-MM-dd HH:mm"),
            make("yyyy-MM-dd"),
            // Сервер в примере присылает meta как dd.MM.yy
            make("dd.MM.yy HH:mm:ss", locale: Locale(identifier: "ru_RU")),
            make("dd.MM.yy HH:mm", locale: Locale(identifier: "ru_RU")),
            make("dd.MM.yy", locale: Locale(identifier: "ru_RU")),
            make("dd.MM.yyyy HH:mm:ss", locale: Locale(identifier: "ru_RU")),
            make("dd.MM.yyyy HH:mm", locale: Locale(identifier: "ru_RU")),
            make("dd.MM.yyyy", locale: Locale(identifier: "ru_RU"))
        ]
    }()

    private static let dayTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    var hasMorePages: Bool {
        currentPage < totalPages
    }
    
    init() {
        self.readKeys = cacheManager.loadReadNotificationKeys()
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
        readKeys = []
        cacheManager.clearReadNotificationKeys()
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
            
            // Обновляем данные, сохраняя прочитанность
            setNotifications(response.data)
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
                setNotifications(cachedNotifications)
            } else {
                appendNotifications(cachedNotifications)
            }
            print("📦 Loaded \(cachedNotifications.count) notifications (page \(page)) from cache")
            return true
        }
        return false
    }
    
    /// Загрузить следующую страницу
    func loadMoreIfNeeded(currentItem: AppNotification) async {
        guard hasMorePages, !isLoadingMore else { return }
        guard let idx = notifications.firstIndex(where: { $0.readKey == currentItem.readKey }) else { return }
        if idx >= max(0, notifications.count - 5) {
            await loadMore()
        }
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
            appendNotifications(response.data)
            totalPages = response.totalPages ?? totalPages
            currentPage = response.page ?? nextPage
            await cacheManager.saveNotificationsAsync(applyReadState(to: response.data), page: nextPage)
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
        readKeys.insert(updatedNotification.readKey)
        cacheManager.saveReadNotificationKeys(readKeys)
        // Перезаписываем кэш первой страницы, чтобы офлайн-режим не терял состояние.
        await cacheManager.saveNotificationsAsync(Array(notifications.prefix(200)), page: 1)
    }
    
    /// Отметить все как прочитанные
    func markAllAsRead() async {
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
        readKeys.formUnion(notifications.map(\.readKey))
        cacheManager.saveReadNotificationKeys(readKeys)
        await cacheManager.saveNotificationsAsync(Array(notifications.prefix(200)), page: 1)
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

        // Группируем по дням из meta-даты (не по строке).
        var order: [Date] = []
        var grouped: [Date: [AppNotification]] = [:]
        var noDate: [AppNotification] = []

        for n in notifications {
            guard let dt = metaDate(from: n.meta) else {
                noDate.append(n)
                continue
            }
            let day = calendar.startOfDay(for: dt)
            if grouped[day] == nil { order.append(day) }
            grouped[day, default: []].append(n)
        }

        order.sort(by: >)

        var result: [NotificationGroup] = []
        result.reserveCapacity(order.count + (noDate.isEmpty ? 0 : 1))
        for day in order {
            let items = grouped[day] ?? []
            result.append(NotificationGroup(id: day, title: Self.dayTitleFormatter.string(from: day), notifications: items))
        }
        if !noDate.isEmpty {
            result.append(NotificationGroup(id: Date.distantPast, title: "Без даты", notifications: noDate))
        }
        groupedNotifications = result
    }

    private func applyReadState(to incoming: [AppNotification]) -> [AppNotification] {
        // Берем persisted readKeys как источник истины.
        if readKeys.isEmpty { return incoming }
        return incoming.map { n in
            var copy = n
            if readKeys.contains(n.readKey) { copy.isRead = true }
            return copy
        }
    }

    private func setNotifications(_ items: [AppNotification]) {
        notifications = normalize(items)
    }

    private func appendNotifications(_ items: [AppNotification]) {
        notifications = normalize(notifications + items)
    }

    private func normalize(_ items: [AppNotification]) -> [AppNotification] {
        let withRead = applyReadState(to: items)
        let sorted = withRead.sorted { a, b in
            let da = metaDate(from: a.meta)
            let db = metaDate(from: b.meta)
            switch (da, db) {
            case let (lhs?, rhs?):
                if lhs != rhs { return lhs > rhs }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            if a.id != b.id { return a.id > b.id }
            if a.caseId != b.caseId { return a.caseId > b.caseId }
            return a.meta > b.meta
        }

        // Дедуп после сортировки: если сервер/пагинация вернули пересечения, оставляем самый "новый".
        var seen = Set<String>()
        seen.reserveCapacity(sorted.count)
        var uniq: [AppNotification] = []
        uniq.reserveCapacity(sorted.count)
        for n in sorted {
            if seen.insert(n.readKey).inserted {
                uniq.append(n)
            }
        }
        return uniq
    }

    private func metaDate(from meta: String) -> Date? {
        let s = meta.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }

        // Строго разбираем серверный формат meta: dd.MM.yy / dd.MM.yyyy (иначе DateFormatter может "перемешать" компоненты).
        if let d = parseDotDate(s) { return d }

        if let d = Self.metaISO8601WithFrac.date(from: s) { return d }
        if let d = Self.metaISO8601.date(from: s) { return d }
        for f in Self.metaFormatters {
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    private func parseDotDate(_ s: String) -> Date? {
        // dd.MM.yy
        if let m = s.wholeMatch(of: /^(?<dd>\d{2})\.(?<mm>\d{2})\.(?<yy>\d{2})$/) {
            guard let dd = Int(m.dd), let mm = Int(m.mm), let yy = Int(m.yy) else { return nil }
            let year = 2000 + yy
            return buildDate(year: year, month: mm, day: dd)
        }
        // dd.MM.yyyy
        if let m = s.wholeMatch(of: /^(?<dd>\d{2})\.(?<mm>\d{2})\.(?<yyyy>\d{4})$/) {
            guard let dd = Int(m.dd), let mm = Int(m.mm), let yyyy = Int(m.yyyy) else { return nil }
            return buildDate(year: yyyy, month: mm, day: dd)
        }
        return nil
    }

    private func buildDate(year: Int, month: Int, day: Int) -> Date? {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.timeZone = .current
        comps.year = year
        comps.month = month
        comps.day = day
        // Полдень, чтобы не ловить "сдвиг дня" при преобразованиях часовых поясов.
        comps.hour = 12
        return comps.date
    }
}
