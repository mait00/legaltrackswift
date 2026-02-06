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
        isSou = try container.decodeIfPresent(Bool.self, forKey: .isSou)
    }
    
    /// Парсинг даты из datetime_start
    var formattedDate: Date? {
        // Парсим ISO формат "2026-01-20T09:30:00"
        if let d = datetimeStart.toDate() {
            return d
        }
        
        // Fallback: пробуем другие форматы
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let d = formatter.date(from: datetimeStart) {
                return d
            }
        }
        
        return nil
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
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "HH:mm"
            let timeStr = formatter.string(from: date)
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
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    
    private let apiService = APIService.shared
    private let cacheManager = CacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let calendar = Calendar.current
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
        errorMessage = nil
        isLoading = false
        print("🗑️ [CalendarViewModel] Data cleared on user change")
    }
    
    // MARK: - Public Methods
    
    /// Загрузить события календаря
    func loadEvents() async {
        errorMessage = nil
        
        // Сначала загружаем из кэша (если есть) - показываем сразу
        if loadFromCache() {
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
            // Получаем сырые данные для кастомного декодирования
            let urlString = "\(AppConstants.API.baseURL)\(APIEndpoint.getCalendarEvents.path)"
            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = KeychainManager.shared.get(forKey: AppConstants.StorageKeys.authToken) {
                request.setValue(token, forHTTPHeaderField: "Authorization")
            }
            
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
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
            
            // Проверяем парсинг дат
            let eventsWithValidDates = sortedEvents.filter { $0.formattedDate != nil }
            let eventsWithInvalidDates = sortedEvents.filter { $0.formattedDate == nil }
            
            if !eventsWithInvalidDates.isEmpty {
                print("⚠️ [Calendar] \(eventsWithInvalidDates.count) events have invalid dates:")
                for event in eventsWithInvalidDates.prefix(5) {
                    print("   - Event ID \(event.id): datetimeStart='\(event.datetimeStart)'")
                }
            }
            
            events = sortedEvents
            
            // Кэшируем результат
            cacheManager.saveCalendarEvents(events)
            
            isLoading = false
            errorMessage = nil
            print("✅ [Calendar] Loaded \(events.count) calendar events (\(eventsWithValidDates.count) with valid dates)")
        } catch {
            isLoading = false
            print("❌ [Calendar] Error loading calendar events: \(error)")
            
            // При ошибке, если кэша не было - показываем ошибку
            if events.isEmpty {
                if loadFromCache() {
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
    private func loadFromCache() -> Bool {
        if let cachedEvents = cacheManager.loadCachedCalendarEvents() {
            events = cachedEvents
            print("📦 Loaded \(cachedEvents.count) calendar events from cache")
            return true
        }
        return false
    }
    
    /// События для выбранной даты
    var eventsForSelectedDate: [CalendarEvent] {
        events.filter { event in
            guard let eventDate = event.formattedDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: selectedDate)
        }.sorted { event1, event2 in
            let time1 = event1.displayTime
            let time2 = event2.displayTime
            return time1 < time2
        }
    }
    
    /// Количество событий на конкретную дату
    func eventsCount(for date: Date) -> Int {
        events.filter { event in
            guard let eventDate = event.formattedDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }.count
    }
    
    /// Проверка наличия событий на дату
    func hasEvents(on date: Date) -> Bool {
        eventsCount(for: date) > 0
    }
    
    /// Получить события на дату
    func events(for date: Date) -> [CalendarEvent] {
        events.filter { event in
            guard let eventDate = event.formattedDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
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
}
