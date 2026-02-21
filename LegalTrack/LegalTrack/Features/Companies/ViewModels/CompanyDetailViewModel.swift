//
//  CompanyDetailViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Модель дела компании (упрощенная версия для списка дел компании)
struct CompanyCase: Codable, Identifiable {
    let id: Int
    let caseNumber: String
    let istec: String?
    let otvetchik: String?
    let status: String?
    let date: String?
    let type: String?
    let meta: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseNumber = "case"
        case istec
        case otvetchik
        case status
        case date
        case type
        case meta
    }
}

/// Ответ с деталями компании
struct CompanyDetailResponse: Codable {
    let message: String?
    let data: CompanyDetailData?
}

/// Данные детальной информации о компании (реальная структура API)
struct CompanyDetailData: Codable {
    let id: Int
    let value: String?
    let inn: String?
    let name: String
    let createdAt: String?
    let lastEvent: String?
    let totalCases: String?
    let new: Int?
    let status: String?
    let nameCustom: String?
    let cases: [CompanyCase]?
    let unrestrictedValue: String?
    let nestedData: CompanyDetailNestedData?
    
    enum CodingKeys: String, CodingKey {
        case id, value, inn, name, status, cases
        case createdAt = "created_at"
        case lastEvent = "last_event"
        case totalCases = "total_cases"
        case new
        case nameCustom = "name_custom"
        case unrestrictedValue = "unrestricted_value"
        case nestedData = "data"
    }
    
    /// Извлечение компании из данных
    var company: Company {
        Company(
            id: id,
            value: value,
            inn: inn,
            name: name,
            description: nil,
            createdAt: createdAt,
            lastEvent: lastEvent,
            totalCases: totalCases,
            new: new,
            status: status,
            nameCustom: nameCustom
        )
    }
}

/// Вложенные данные (если есть)
struct CompanyDetailNestedData: Codable {
    // Может содержать дополнительные данные
}

/// ViewModel для детальной страницы компании
@MainActor
final class CompanyDetailViewModel: ObservableObject {
    @Published private(set) var company: Company?
    @Published private(set) var cases: [CompanyCase] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    
    private let apiService = APIService.shared

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
    
    /// Загрузить детали компании
    func loadCompanyDetail(companyId: Int) async {
        isLoading = true
        errorMessage = nil
        
        let endpoint = APIEndpoint.detailCompany(id: companyId).path
        print("🏢 [CompanyDetail] Loading company detail for id: \(companyId)")
        
        do {
            let response: CompanyDetailResponse = try await apiService.request(
                endpoint: endpoint,
                method: .get
            )
            
            print("🏢 [CompanyDetail] Response received")
            
            if let data = response.data {
                self.company = data.company
                self.cases = sortCompanyCases(data.cases ?? [])
                print("🏢 [CompanyDetail] Company: \(data.company.name), cases: \(cases.count)")
                isLoading = false
                errorMessage = nil
            } else {
                // Если API не вернул data, пробуем загрузить компанию из подписок
                await loadCompanyFromSubscriptions(companyId: companyId)
                isLoading = false
                if company == nil {
                    errorMessage = "Не удалось загрузить данные компании"
                }
            }
        } catch is CancellationError {
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            print("❌ [CompanyDetail] Error: \(error)")
            
            // При ошибке пробуем загрузить из подписок
            await loadCompanyFromSubscriptions(companyId: companyId)
            
            if company == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Загрузить компанию из списка подписок (fallback)
    private func loadCompanyFromSubscriptions(companyId: Int) async {
        print("🏢 [CompanyDetail] Trying to load from subscriptions...")
        
        do {
            let response: SubscriptionsResponse = try await apiService.request(
                endpoint: APIEndpoint.getSubscriptions.path,
                method: .get
            )
            
            if let foundCompany = response.companies.first(where: { $0.id == companyId }) {
                self.company = foundCompany
                print("🏢 [CompanyDetail] Found company in subscriptions: \(foundCompany.name)")
            }
        } catch is CancellationError {
            return
        } catch {
            print("❌ [CompanyDetail] Failed to load from subscriptions: \(error)")
        }
    }

    /// Удалить компанию из мониторинга
    func deleteCompany(companyId: Int) async -> Bool {
        struct DeleteResponse: Codable {
            let success: Bool?
            let status: String?
            let message: String?
        }

        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }

        do {
            let endpoint = APIEndpoint.deleteSubscription(id: companyId, type: "company").path
            let response: DeleteResponse = try await apiService.request(
                endpoint: endpoint,
                method: .get
            )

            let status = response.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let message = response.message?.lowercased() ?? ""
            let isSuccess = response.success == true
                || status == "success"
                || message.contains("успех")
                || (message.contains("подписк") && message.contains("удален"))

            if isSuccess {
                return true
            } else {
                errorMessage = response.message ?? "Не удалось удалить компанию"
                return false
            }
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func sortCompanyCases(_ items: [CompanyCase]) -> [CompanyCase] {
        items.sorted { a, b in
            let da = companyCaseDate(a)
            let db = companyCaseDate(b)
            if da != db { return da > db }
            return a.id > b.id
        }
    }

    private func companyCaseDate(_ item: CompanyCase) -> Date {
        if let meta = item.meta, let d = parseDate(meta) { return d }
        if let date = item.date, let d = parseDate(date) { return d }
        return .distantPast
    }

    private func parseDate(_ raw: String) -> Date? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }

        // dd.MM.yy / dd.MM.yyyy
        if let d = parseDotDate(s) { return d }

        if let d = Self.iso8601WithFrac.date(from: s) { return d }
        if let d = Self.iso8601.date(from: s) { return d }
        return nil
    }

    private func parseDotDate(_ s: String) -> Date? {
        // dd.MM.yy
        if let m = s.wholeMatch(of: /^(?<dd>\d{2})\.(?<mm>\d{2})\.(?<yy>\d{2})$/) {
            guard let dd = Int(m.dd), let mm = Int(m.mm), let yy = Int(m.yy) else { return nil }
            return buildDate(year: 2000 + yy, month: mm, day: dd)
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
        comps.hour = 12
        return comps.date
    }
}
