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
    @Published private(set) var errorMessage: String?
    
    private let apiService = APIService.shared
    
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
                self.cases = data.cases ?? []
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
        } catch {
            print("❌ [CompanyDetail] Failed to load from subscriptions: \(error)")
        }
    }
}



