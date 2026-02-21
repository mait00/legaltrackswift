//
//  DaDataService.swift
//  LegalTrack
//
//  Сервис для работы с DaData API (автодополнение компаний)
//

import Foundation

/// Сервис для работы с DaData API
@MainActor
final class DaDataService {
    static let shared = DaDataService()
    
    private let apiKey = AppConstants.DaData.apiKey
    private let secretKey = AppConstants.DaData.secretKey
    private let baseURL = AppConstants.DaData.baseURL
    
    private init() {}
    
    /// Поиск компаний по запросу (ИНН или название)
    func searchCompanies(query: String) async throws -> [DaDataCompany] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        guard let url = URL(string: "\(baseURL)/suggest/party") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": query,
            "count": 20
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [DaData] HTTP Error: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DaDataResponse.self, from: data)
        
        return result.suggestions.map { $0.data }
    }
    
    /// Поиск компании по ИНН
    func findCompanyByINN(_ inn: String) async throws -> DaDataCompany? {
        let companies = try await searchCompanies(query: inn)
        return companies.first { $0.inn == inn }
    }
}

// MARK: - DaData Models

struct DaDataResponse: Codable {
    let suggestions: [DaDataSuggestion]
}

struct DaDataSuggestion: Codable {
    let value: String
    let unrestrictedValue: String
    let data: DaDataCompany
    
    enum CodingKeys: String, CodingKey {
        case value
        case unrestrictedValue = "unrestricted_value"
        case data
    }
}

struct DaDataCompany: Codable, Identifiable {
    var id: String { inn ?? kpp ?? ogrn ?? UUID().uuidString }
    
    let inn: String?
    let kpp: String?
    let ogrn: String?
    let ogrnDate: Int?
    let name: DaDataName
    let fullName: String?
    let shortName: String?
    let address: DaDataAddress?
    let state: DaDataState?
    let management: DaDataManagement?
    let branchType: String?
    let branchCount: Int?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case inn, kpp, ogrn
        case ogrnDate = "ogrn_date"
        case name
        case fullName = "name_full_with_opf"
        case shortName = "name_short_with_opf"
        case address
        case state
        case management
        case branchType = "branch_type"
        case branchCount = "branch_count"
        case type
    }
    
    /// Полное название компании
    var displayName: String {
        fullName ?? name.full ?? name.short ?? shortName ?? "Неизвестная компания"
    }
    
    /// Краткое название
    var shortDisplayName: String {
        name.short ?? shortName ?? name.full ?? fullName ?? "Неизвестная компания"
    }
    
    /// Статус компании
    var statusText: String {
        guard let state = state else { return "Статус неизвестен" }
        if state.status == "ACTIVE" {
            return "Действующая"
        } else if state.status == "LIQUIDATING" {
            return "Ликвидируется"
        } else if state.status == "LIQUIDATED" {
            return "Ликвидирована"
        } else {
            return state.status ?? "Неизвестен"
        }
    }
    
    /// Адрес
    var addressText: String {
        address?.value ?? "Адрес не указан"
    }
}

struct DaDataName: Codable {
    let full: String?
    let short: String?
    let fullWithOpf: String?
    let shortWithOpf: String?
    
    enum CodingKeys: String, CodingKey {
        case full
        case short
        case fullWithOpf = "full_with_opf"
        case shortWithOpf = "short_with_opf"
    }
}

struct DaDataAddress: Codable {
    let value: String?
    let unrestrictedValue: String?
    
    enum CodingKeys: String, CodingKey {
        case value
        case unrestrictedValue = "unrestricted_value"
    }
}

struct DaDataState: Codable {
    let status: String?
    let actualityDate: Int?
    let registrationDate: Int?
    let liquidationDate: Int?
    
    enum CodingKeys: String, CodingKey {
        case status
        case actualityDate = "actuality_date"
        case registrationDate = "registration_date"
        case liquidationDate = "liquidation_date"
    }
}

struct DaDataManagement: Codable {
    let name: String?
    let post: String?
    let disqualified: Bool?
}
