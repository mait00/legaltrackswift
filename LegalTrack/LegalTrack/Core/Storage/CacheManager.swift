//
//  CacheManager.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Менеджер кэширования для офлайн режима
final class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let ioQueue = DispatchQueue(label: "CacheManager.IO", qos: .utility)
    private static let cacheSuiteName = "ru.legalsystems.legaltrack.cache"
    private let cacheDefaults: UserDefaults
    private let cacheDirectory: URL
    private let casesDirectory: URL
    private let pdfDirectory: URL
    
    // Время жизни кэша (7 дней)
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60
    private let readNotificationKeysKey = "read_notification_keys_v1"
    
    private init() {
        self.cacheDefaults = UserDefaults(suiteName: Self.cacheSuiteName) ?? .standard
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesURL.appendingPathComponent("LegalTrackCache", isDirectory: true)
        casesDirectory = cacheDirectory.appendingPathComponent("cases", isDirectory: true)
        pdfDirectory = cacheDirectory.appendingPathComponent("pdf", isDirectory: true)
        
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Setup
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: casesDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Cases Caching
    
    /// Сохранить список дел в кэш
    func saveCases(_ cases: [LegalCase]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(cases)
            let fileURL = casesDirectory.appendingPathComponent("cases_list.json")
            try data.write(to: fileURL)
            
            // Сохраняем время кэширования
            saveCacheTimestamp(for: "cases_list")
            print("💾 [CacheManager] Saved \(cases.count) cases to cache")
        } catch {
            print("❌ [CacheManager] Failed to save cases: \(error)")
        }
    }

    /// Асинхронно сохранить список дел в кэш, чтобы не блокировать main thread
    func saveCasesAsync(_ cases: [LegalCase]) async {
        await performIO { [weak self] in
            self?.saveCases(cases)
        }
    }
    
    /// Загрузить список дел из кэша
    func loadCachedCases() -> [LegalCase]? {
        let fileURL = casesDirectory.appendingPathComponent("cases_list.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📦 [CacheManager] No cached cases file found")
            return nil
        }
        
        // Не проверяем срок действия - показываем кэш даже если он "просрочен"
        // (обновление произойдёт в фоне)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cases = try decoder.decode([LegalCase].self, from: data)
            print("📦 [CacheManager] Loaded \(cases.count) cases from cache")
            return cases
        } catch {
            print("❌ [CacheManager] Failed to load cases: \(error)")
            return nil
        }
    }

    /// Асинхронно загрузить список дел из кэша
    func loadCachedCasesAsync() async -> [LegalCase]? {
        await performIO { [weak self] in
            self?.loadCachedCases()
        }
    }
    
    // MARK: - Case Detail Caching
    
    /// Сохранить детали дела в кэш
    func saveCaseDetail(_ detail: CaseDetailData, for caseId: Int) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(detail)
            let fileURL = casesDirectory.appendingPathComponent("case_\(caseId).json")
            try data.write(to: fileURL)
            saveCacheTimestamp(for: "case_\(caseId)")
            print("💾 [CacheManager] Saved case detail \(caseId) to cache")
        } catch {
            print("❌ [CacheManager] Failed to save case detail: \(error)")
        }
    }

    func saveCaseDetailAsync(_ detail: CaseDetailData, for caseId: Int) async {
        await performIO { [weak self] in
            self?.saveCaseDetail(detail, for: caseId)
        }
    }
    
    /// Загрузить детали дела из кэша
    func loadCachedCaseDetail(for caseId: Int) -> CaseDetailData? {
        let fileURL = casesDirectory.appendingPathComponent("case_\(caseId).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Для деталей дела не проверяем срок действия - показываем даже старый кэш
        // (обновление произойдёт в фоне)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let detail = try decoder.decode(CaseDetailData.self, from: data)
            print("📦 [CacheManager] Loaded case detail \(caseId) from cache")
            return detail
        } catch {
            print("❌ [CacheManager] Failed to load case detail: \(error)")
            return nil
        }
    }

    func loadCachedCaseDetailAsync(for caseId: Int) async -> CaseDetailData? {
        await performIO { [weak self] in
            self?.loadCachedCaseDetail(for: caseId)
        }
    }
    
    // MARK: - Companies Caching
    
    /// Сохранить список компаний в кэш
    func saveCompanies(_ companies: [Company]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(companies)
            let fileURL = casesDirectory.appendingPathComponent("companies_list.json")
            try data.write(to: fileURL)
            saveCacheTimestamp(for: "companies_list")
            print("💾 [CacheManager] Saved \(companies.count) companies to cache")
        } catch {
            print("❌ [CacheManager] Failed to save companies: \(error)")
        }
    }

    func saveCompaniesAsync(_ companies: [Company]) async {
        await performIO { [weak self] in
            self?.saveCompanies(companies)
        }
    }
    
    /// Загрузить список компаний из кэша
    func loadCachedCompanies() -> [Company]? {
        let fileURL = casesDirectory.appendingPathComponent("companies_list.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📦 [CacheManager] No cached companies file found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let companies = try decoder.decode([Company].self, from: data)
            print("📦 [CacheManager] Loaded \(companies.count) companies from cache")
            return companies
        } catch {
            print("❌ [CacheManager] Failed to load companies: \(error)")
            return nil
        }
    }

    func loadCachedCompaniesAsync() async -> [Company]? {
        await performIO { [weak self] in
            self?.loadCachedCompanies()
        }
    }
    
    // MARK: - Calendar Caching
    
    /// Сохранить события календаря в кэш
    func saveCalendarEvents(_ events: [CalendarEvent]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(events)
            let fileURL = casesDirectory.appendingPathComponent("calendar_events.json")
            try data.write(to: fileURL)
            saveCacheTimestamp(for: "calendar_events")
            print("💾 [CacheManager] Saved \(events.count) calendar events to cache")
        } catch {
            print("❌ [CacheManager] Failed to save calendar events: \(error)")
        }
    }

    func saveCalendarEventsAsync(_ events: [CalendarEvent]) async {
        await performIO { [weak self] in
            self?.saveCalendarEvents(events)
        }
    }
    
    /// Загрузить события календаря из кэша
    func loadCachedCalendarEvents() -> [CalendarEvent]? {
        let fileURL = casesDirectory.appendingPathComponent("calendar_events.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📦 [CacheManager] No cached calendar events file found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([CalendarEvent].self, from: data)
            print("📦 [CacheManager] Loaded \(events.count) calendar events from cache")
            return events
        } catch {
            print("❌ [CacheManager] Failed to load calendar events: \(error)")
            return nil
        }
    }

    func loadCachedCalendarEventsAsync() async -> [CalendarEvent]? {
        await performIO { [weak self] in
            self?.loadCachedCalendarEvents()
        }
    }
    
    // MARK: - Notifications Caching
    
    /// Сохранить уведомления в кэш
    func saveNotifications(_ notifications: [AppNotification], page: Int = 1) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(notifications)
            let fileURL = casesDirectory.appendingPathComponent("notifications_page_\(page).json")
            try data.write(to: fileURL)
            saveCacheTimestamp(for: "notifications_page_\(page)")
            print("💾 [CacheManager] Saved \(notifications.count) notifications (page \(page)) to cache")
        } catch {
            print("❌ [CacheManager] Failed to save notifications: \(error)")
        }
    }

    func saveNotificationsAsync(_ notifications: [AppNotification], page: Int = 1) async {
        await performIO { [weak self] in
            self?.saveNotifications(notifications, page: page)
        }
    }
    
    /// Загрузить уведомления из кэша
    func loadCachedNotifications(page: Int = 1) -> [AppNotification]? {
        let fileURL = casesDirectory.appendingPathComponent("notifications_page_\(page).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let notifications = try decoder.decode([AppNotification].self, from: data)
            print("📦 [CacheManager] Loaded \(notifications.count) notifications (page \(page)) from cache")
            return notifications
        } catch {
            print("❌ [CacheManager] Failed to load notifications: \(error)")
            return nil
        }
    }

    func loadCachedNotificationsAsync(page: Int = 1) async -> [AppNotification]? {
        await performIO { [weak self] in
            self?.loadCachedNotifications(page: page)
        }
    }

    // MARK: - Notifications Read State

    func loadReadNotificationKeys() -> Set<String> {
        let arr = cacheDefaults.array(forKey: readNotificationKeysKey) as? [String] ?? []
        return Set(arr)
    }

    func saveReadNotificationKeys(_ keys: Set<String>) {
        // Ограничиваем, чтобы не раздувать UserDefaults бесконечно.
        let capped = Array(keys.prefix(10_000))
        cacheDefaults.set(capped, forKey: readNotificationKeysKey)
    }

    func clearReadNotificationKeys() {
        cacheDefaults.removeObject(forKey: readNotificationKeysKey)
    }
    
    // MARK: - PDF Caching
    
    /// Скачать и закэшировать PDF документ
    func downloadAndCachePDF(from urlString: String, caseId: Int, documentId: String) async -> URL? {
        // Генерируем имя файла (используем безопасные символы и хэш URL для уникальности)
        let safeDocumentId = documentId.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        // Добавляем хэш URL для уникальности (на случай разных URL для одного документа)
        let urlHash = String(urlString.hashValue)
        let fileName = "case_\(caseId)_\(safeDocumentId)_\(urlHash).pdf"
        let localURL = pdfDirectory.appendingPathComponent(fileName)
        
        // Проверяем, есть ли уже в кэше
        if fileManager.fileExists(atPath: localURL.path) {
            // Проверяем, что файл не пустой
            if let attributes = try? fileManager.attributesOfItem(atPath: localURL.path),
               let fileSize = attributes[.size] as? Int64, fileSize > 0 {
                print("📦 [CacheManager] PDF found in cache: \(fileName) (\(fileSize) bytes)")
                return localURL
            } else {
                print("⚠️ [CacheManager] Cached PDF file is empty or corrupted, re-downloading")
                try? fileManager.removeItem(at: localURL)
            }
        }
        
        // Также проверяем старый формат имени файла (без хэша) для обратной совместимости
        let oldFileName = "case_\(caseId)_\(safeDocumentId).pdf"
        let oldLocalURL = pdfDirectory.appendingPathComponent(oldFileName)
        if fileManager.fileExists(atPath: oldLocalURL.path) {
            if let attributes = try? fileManager.attributesOfItem(atPath: oldLocalURL.path),
               let fileSize = attributes[.size] as? Int64, fileSize > 0 {
                print("📦 [CacheManager] PDF found in cache (old format): \(oldFileName) (\(fileSize) bytes)")
                // Переименовываем в новый формат
                try? fileManager.moveItem(at: oldLocalURL, to: localURL)
                return localURL
            }
        }
        
        // Скачиваем
        guard let url = URL(string: urlString) else {
            print("❌ [CacheManager] Invalid PDF URL: \(urlString)")
            return nil
        }
        
        print("📥 [CacheManager] Downloading PDF from: \(urlString)")
        
        do {
            // Создаём запрос с авторизацией (если это наш API)
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0
            
            // Если это запрос к нашему API или archive.legaltrack.ru - добавляем токен авторизации
            if urlString.contains(AppConstants.API.baseURL) || urlString.contains("archive.legaltrack.ru") {
                if let token = KeychainManager.shared.get(forKey: AppConstants.StorageKeys.authToken) {
                    request.setValue(token, forHTTPHeaderField: "Authorization")
                    print("🔑 [CacheManager] Using auth token for request to: \(url.host ?? "unknown")")
                } else {
                    print("⚠️ [CacheManager] No auth token available for request to: \(url.host ?? "unknown")")
                }
            }
            
            // Устанавливаем Accept header для PDF
            request.setValue("application/pdf, */*", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [CacheManager] Invalid response type")
                return nil
            }
            
            print("📊 [CacheManager] PDF download response: HTTP \(httpResponse.statusCode), size: \(data.count) bytes")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ [CacheManager] Failed to download PDF: HTTP \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("   Response: \(errorString.prefix(500))")
                }
                // Проверяем Content-Type
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    print("   Content-Type: \(contentType)")
                }
                return nil
            }
            
            // Проверяем, что это действительно PDF
            if data.count < 4 {
                print("❌ [CacheManager] PDF file too small: \(data.count) bytes")
                return nil
            }
            
            // Проверяем PDF заголовок (%PDF)
            let pdfHeader = data.prefix(4)
            let headerString = String(data: pdfHeader, encoding: .ascii) ?? ""
            
            // Проверяем, не является ли это HTML (например, страница с капчей)
            let htmlHeader = data.prefix(15)
            let htmlString = String(data: htmlHeader, encoding: .ascii) ?? ""
            if htmlString.uppercased().contains("<!DOCTYPE") || htmlString.uppercased().contains("<HTML") {
                print("❌ [CacheManager] Server returned HTML instead of PDF (likely captcha or error page)")
                if let errorString = String(data: data.prefix(500), encoding: .utf8) {
                    print("   HTML preview: \(errorString.prefix(200))")
                }
                return nil
            }
            
            if headerString != "%PDF" {
                print("⚠️ [CacheManager] File doesn't appear to be PDF (header: \(headerString))")
                // Проверяем Content-Type из заголовков
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                   contentType.contains("pdf") {
                    print("   Content-Type indicates PDF, proceeding...")
                } else {
                    print("❌ [CacheManager] Content-Type doesn't indicate PDF: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown")")
                    return nil
                }
            } else {
                print("✅ [CacheManager] Valid PDF header detected")
            }
            
            try data.write(to: localURL)
            print("💾 [CacheManager] Downloaded and cached PDF: \(fileName) (\(data.count) bytes)")
            return localURL
        } catch {
            print("❌ [CacheManager] Failed to download PDF: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URL Error: \(urlError.code.rawValue) - \(urlError.localizedDescription)")
            }
            return nil
        }
    }
    
    /// Получить закэшированный PDF
    func getCachedPDF(caseId: Int, documentId: String) -> URL? {
        let safeDocumentId = documentId.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        do {
            let files = try fileManager.contentsOfDirectory(at: pdfDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            // Сначала ищем новый формат (с хэшем)
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("case_\(caseId)_\(safeDocumentId)_") && fileName.hasSuffix(".pdf") {
                    if let attributes = try? file.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = attributes.fileSize, fileSize > 0 {
                        print("📦 [CacheManager] Found cached PDF: \(fileName) (\(fileSize) bytes)")
                        return file
                    }
                }
            }
            
            // Потом ищем старый формат
            let oldFileName = "case_\(caseId)_\(safeDocumentId).pdf"
            let oldLocalURL = pdfDirectory.appendingPathComponent(oldFileName)
            if fileManager.fileExists(atPath: oldLocalURL.path) {
                if let attributes = try? oldLocalURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = attributes.fileSize, fileSize > 0 {
                    print("📦 [CacheManager] Found cached PDF (old format): \(oldFileName) (\(fileSize) bytes)")
                    return oldLocalURL
                }
            }
        } catch {
            print("❌ [CacheManager] Error searching for cached PDF: \(error)")
        }
        
        return nil
    }
    
    /// Получить все закэшированные PDF для дела
    func getCachedPDFs(for caseId: Int) -> [URL] {
        let prefix = "case_\(caseId)_"
        
        do {
            let files = try fileManager.contentsOfDirectory(at: pdfDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.lastPathComponent.hasPrefix(prefix) && $0.pathExtension == "pdf" }
        } catch {
            return []
        }
    }
    
    // MARK: - Cache Timestamps
    
    private func saveCacheTimestamp(for key: String) {
        cacheDefaults.set(Date(), forKey: "cache_timestamp_\(key)")
    }
    
    private func isCacheExpired(for key: String) -> Bool {
        guard let timestamp = cacheDefaults.object(forKey: "cache_timestamp_\(key)") as? Date else {
            return true
        }
        return Date().timeIntervalSince(timestamp) > cacheExpirationInterval
    }
    
    /// Получить время последней синхронизации
    func getLastSyncTime(for key: String = "cases_list") -> Date? {
        return cacheDefaults.object(forKey: "cache_timestamp_\(key)") as? Date
    }
    
    // MARK: - Cache Management
    
    /// Очистить весь кэш
    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        createDirectoriesIfNeeded()
        
        // Удаляем timestamps (в отдельном suite, чтобы не лочить UserDefaults.standard)
        let keys = cacheDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("cache_timestamp_") }
        keys.forEach { cacheDefaults.removeObject(forKey: $0) }

        // Удаляем локальные состояния (прочитанность и т.п.)
        clearReadNotificationKeys()
        
        print("🗑️ [CacheManager] All cache cleared")
    }

    func clearAllCacheAsync() async {
        await performIO { [weak self] in
            self?.clearAllCache()
        }
    }
    
    /// Удалить кэш для конкретного ключа
    func removeCache(forKey key: String) {
        let fileURL: URL
        
        switch key {
        case "subscriptions", "cases_list":
            fileURL = casesDirectory.appendingPathComponent("cases_list.json")
        case let caseKey where caseKey.hasPrefix("case_"):
            fileURL = casesDirectory.appendingPathComponent("\(caseKey).json")
        case "companies":
            fileURL = cacheDirectory.appendingPathComponent("companies.json")
        default:
            fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        }
        
        try? fileManager.removeItem(at: fileURL)
        
        // Удаляем timestamp
        cacheDefaults.removeObject(forKey: "cache_timestamp_\(key)")
        
        print("🗑️ [CacheManager] Cache cleared for key: \(key)")
    }
    
    /// Получить размер кэша
    func getCacheSize() -> String {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    // MARK: - Async IO helper

    private func performIO<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            ioQueue.async {
                continuation.resume(returning: work())
            }
        }
    }
}

// MARK: - Network Connectivity

import Network

/// Мониторинг сетевого подключения
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
                
                if path.status != .satisfied {
                    print("📡 [NetworkMonitor] Offline mode")
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}
