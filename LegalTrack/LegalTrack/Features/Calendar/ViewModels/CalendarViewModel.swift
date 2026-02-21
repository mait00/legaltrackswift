//
//  CalendarViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine

// MARK: - Calendar Event Model

/// Модель события календаря (соответствует реальной структуре API)
struct CalendarEvent: Codable, Identifiable {
    let id: Int
    let datetimeStart: String
    let caseId: Int?
    let head: String
    let secondLine: String
    let thirdLine: String?
    let isSou: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case datetimeStart = "datetime_start"
        case caseId = "case_id"
        case head
        case secondLine = "second_line"
        case thirdLine = "third_line"
        case isSou = "is_sou"
    }
    
    /// Кастомный инициализатор для декодирования
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        datetimeStart = try container.decode(String.self, forKey: .datetimeStart)
        caseId = try container.decodeIfPresent(Int.self, forKey: .caseId)
        head = try container.decode(String.self, forKey: .head)
        secondLine = try container.decode(String.self, forKey: .secondLine)
        thirdLine = try container.decodeIfPresent(String.self, forKey: .thirdLine)
        isSou = container.decodeBoolLikeIfPresent(forKey: .isSou)
    }
    
    /// Парсинг даты из datetime_start
    var formattedDate: Date? {
        if let d = CalendarEvent.isoDateTimeFormatter.date(from: datetimeStart) {
            return d
        }
        if let d = CalendarEvent.fallbackDateTimeFormatter.date(from: datetimeStart) {
            return d
        }
        return CalendarEvent.shortDateFormatter.date(from: datetimeStart)
    }
    
    /// Заголовок события (номер дела)
    var title: String {
        head
    }
    
    /// Номер дела
    var caseNumber: String? {
        head
    }
    
    /// Время события для отображения
    var displayTime: String {
        if let date = formattedDate {
            let timeStr = CalendarEvent.timeFormatter.string(from: date)
            return timeStr == "00:00" ? "" : timeStr
        }
        return ""
    }
    
    /// Описание события (вторая строка)
    var description: String? {
        secondLine.isEmpty ? nil : secondLine
    }
    
    /// Тип события (всегда заседание для календаря)
    var type: String? {
        "hearing"
    }
    
    /// Тип события с цветом
    var eventColor: Color {
        return .blue // Все события в календаре - заседания
    }
    
    /// Локализованный тип события
    var localizedType: String {
        "Заседание"
    }
    
    /// Извлечение суда из second_line
    var court: String? {
        // Парсим second_line: "Заседание по делу А40-60261/2024 в АС города Москвы. Судья Морозова М. В."
        // Ищем текст после "в " и до "."
        if let range = secondLine.range(of: " в ") {
            let afterIn = String(secondLine[range.upperBound...])
            if let dotRange = afterIn.range(of: ".") {
                return String(afterIn[..<dotRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    /// Извлечение судьи из second_line
    var judge: String? {
        // Парсим second_line: "Заседание по делу А40-60261/2024 в АС города Москвы. Судья Морозова М. В."
        // Ищем текст после "Судья "
        if let range = secondLine.range(of: "Судья ") {
            let afterJudge = String(secondLine[range.upperBound...])
            return afterJudge.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    /// Кабинет (не предоставляется API)
    var cabinet: String? {
        nil
    }
    
    /// Заголовок дела (для совместимости)
    var caseTitle: String? {
        head
    }

    private static let isoDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static let fallbackDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Calendar API Response

/// Ответ API календаря (реальная структура)
struct CalendarResponse: Codable {
    let message: String?
    let data: [CalendarEvent]? // data - это массив событий напрямую
    
    /// Извлечение всех событий из ответа
    var allEvents: [CalendarEvent] {
        return data ?? []
    }
}

// MARK: - Calendar ViewModel

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = [] {
        didSet { rebuildEventsByDay() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published private(set) var caseDisplayNames: [Int: String] = [:]
    @Published private(set) var caseDisplayNamesByNumber: [String: String] = [:]
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let calendar = Calendar.current
    private var eventsByDay: [Date: [CalendarEvent]] = [:]
    private var cancellables = Set<AnyCancellable>()
    
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
        events = []
        caseDisplayNames = [:]
        caseDisplayNamesByNumber = [:]
        errorMessage = nil
        isLoading = false
        print("🗑️ [CalendarViewModel] Data cleared on user change")
    }
    
    // MARK: - Public Methods
    
    /// Загрузить события календаря
    func loadEvents() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if await loadFromCache() {
            print("📦 [Calendar] Showing cached events first")
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
                endpoint: APIEndpoint.getCalendarEvents.path,
                method: .get
            )
            
            // Используем кастомный декодер без convertFromSnakeCase
            let decoder = JSONDecoder()
            let calendarResponse = try decoder.decode(CalendarResponse.self, from: data)
            
            print("📅 [Calendar] Received response with \(calendarResponse.allEvents.count) events")
            
            // Обновляем данные
            let sortedEvents = calendarResponse.allEvents.sorted { event1, event2 in
                guard let d1 = event1.formattedDate, let d2 = event2.formattedDate else {
                    return false
                }
                return d1 < d2
            }
            
            events = sortedEvents
            
            // Кэшируем результат
            await cacheManager.saveCalendarEventsAsync(events)
            await refreshCaseDisplayNames()
            
            isLoading = false
            errorMessage = nil
            print("✅ [Calendar] Loaded \(events.count) calendar events")
        } catch is CancellationError {
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            print("❌ [Calendar] Error loading calendar events: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if events.isEmpty {
                if await loadFromCache() {
                    errorMessage = nil
                    print("📦 [Calendar] Using cached events after error")
                } else {
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription ?? error.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    events = []
                    print("❌ [Calendar] No cache available, showing error: \(errorMessage ?? "Unknown")")
                }
            } else {
                // Если кэш уже показан - не показываем ошибку
                errorMessage = nil
                print("📦 [Calendar] Keeping cached events, error ignored")
            }
        }
    }
    
    /// Загрузить из кэша
    @discardableResult
    private func loadFromCache() async -> Bool {
        if let cachedEvents = await cacheManager.loadCachedCalendarEventsAsync() {
            events = cachedEvents
            await refreshCaseDisplayNames()
            print("📦 Loaded \(cachedEvents.count) calendar events from cache")
            return true
        }
        return false
    }

    /// Возвращает отображаемый заголовок события:
    /// пользовательское имя дела (если есть) или исходный заголовок из календаря.
    func displayTitle(for event: CalendarEvent) -> String {
        if let id = event.caseId, let custom = caseDisplayNames[id], !custom.isEmpty {
            return custom
        }
        let normalizedNumber = Self.normalizeCaseNumber(event.caseNumber ?? event.title)
        if let custom = caseDisplayNamesByNumber[normalizedNumber], !custom.isEmpty {
            return custom
        }
        return event.title
    }
    
    /// События для выбранной даты
    var eventsForSelectedDate: [CalendarEvent] {
        let dayKey = calendar.startOfDay(for: selectedDate)
        return eventsByDay[dayKey] ?? []
    }
    
    /// Количество событий на конкретную дату
    func eventsCount(for date: Date) -> Int {
        let dayKey = calendar.startOfDay(for: date)
        return eventsByDay[dayKey]?.count ?? 0
    }
    
    /// Проверка наличия событий на дату
    func hasEvents(on date: Date) -> Bool {
        eventsCount(for: date) > 0
    }
    
    /// Получить события на дату
    func events(for date: Date) -> [CalendarEvent] {
        let dayKey = calendar.startOfDay(for: date)
        return eventsByDay[dayKey] ?? []
    }
    
    /// Типы событий на дату (для отображения индикаторов)
    func eventTypes(for date: Date) -> [String] {
        Array(Set(events(for: date).compactMap { $0.type }))
    }
    
    /// Переход к предыдущему месяцу
    func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    /// Переход к следующему месяцу
    func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    /// Переход к сегодняшней дате
    func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Date()
            selectedDate = Date()
        }
    }
    
    /// Дни для отображения в текущем месяце
    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDay = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        // Определяем день недели первого дня (понедельник = 0)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7 // Понедельник = 0
        
        // Добавляем пустые ячейки для выравнивания
        var days: [Date?] = Array(repeating: nil, count: adjustedFirstWeekday)
        
        // Добавляем все дни месяца
        var currentDate = firstDay
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    /// Название текущего месяца
    var monthTitle: String {
        CalendarViewModel.monthTitleFormatter.string(from: currentMonth).capitalized
    }
    
    /// Проверка, является ли дата сегодняшней
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /// Проверка, выбрана ли дата
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    /// Проверка, принадлежит ли дата текущему месяцу
    func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private func rebuildEventsByDay() {
        var grouped: [Date: [CalendarEvent]] = [:]
        grouped.reserveCapacity(events.count)

        for event in events {
            guard let eventDate = event.formattedDate else { continue }
            let dayKey = calendar.startOfDay(for: eventDate)
            grouped[dayKey, default: []].append(event)
        }

        eventsByDay = grouped
    }

    private func refreshCaseDisplayNames() async {
        var resultById: [Int: String] = [:]
        var resultByNumber: [String: String] = [:]

        // 1) Быстрый источник — локальный кэш подписок.
        if let cachedCases = await cacheManager.loadCachedCasesAsync() {
            for legalCase in cachedCases {
                let preferred = (legalCase.name ?? legalCase.title ?? legalCase.value ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let number = (legalCase.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !preferred.isEmpty, preferred != number {
                    resultById[legalCase.id] = preferred
                    resultByNumber[Self.normalizeCaseNumber(number)] = preferred
                }
            }
        }

        // 2) Актуализация с сервера (если онлайн), чтобы сразу видеть последние переименования.
        if networkMonitor.isConnected {
            do {
                let response: SubscriptionsResponse = try await apiService.request(
                    endpoint: APIEndpoint.getSubscriptions.path,
                    method: .get
                )
                for legalCase in response.cases {
                    let preferred = (legalCase.name ?? legalCase.title ?? legalCase.value ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let number = (legalCase.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !preferred.isEmpty, preferred != number {
                        resultById[legalCase.id] = preferred
                        resultByNumber[Self.normalizeCaseNumber(number)] = preferred
                    }
                }
            } catch {
                // Не блокируем календарь из-за ошибки синхронизации имен.
            }
        }

        caseDisplayNames = resultById
        caseDisplayNamesByNumber = resultByNumber
    }

    private static func normalizeCaseNumber(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
}
