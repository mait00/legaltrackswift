//
//  AddCompanyViewModel.swift
//  LegalTrack
//
//  ViewModel для добавления компании с DaData автодополнением
//

import Foundation

@MainActor
final class AddCompanyViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var suggestions: [DaDataCompany] = []
    @Published var selectedCompany: DaDataCompany?
    @Published var isLoading = false
    @Published var isAdding = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let apiService = APIService.shared
    private let daDataService = DaDataService.shared
    
    private var searchTask: Task<Void, Never>?
    
    /// Поиск компаний через DaData
    func searchCompanies() {
        // Отменяем предыдущий поиск
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        
        // Минимальная длина для поиска
        guard searchQuery.count >= 3 else {
            suggestions = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        searchTask = Task {
            do {
                let results = try await daDataService.searchCompanies(query: searchQuery)
                
                // Проверяем, не отменена ли задача
                guard !Task.isCancelled else { return }
                
                suggestions = results
                isLoading = false
                
                print("✅ [DaData] Found \(results.count) companies")
            } catch {
                guard !Task.isCancelled else { return }
                
                isLoading = false
                errorMessage = "Не удалось найти компании"
                print("❌ [DaData] Search error: \(error)")
            }
        }
    }
    
    /// Выбрать компанию из предложений
    func selectCompany(_ company: DaDataCompany) {
        selectedCompany = company
        searchQuery = company.displayName
        suggestions = []
    }
    
    /// Добавить компанию в мониторинг
    func addCompany() async -> Bool {
        guard let company = selectedCompany,
              let inn = company.inn else {
            errorMessage = "Выберите компанию из списка"
            return false
        }
        
        isAdding = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Используем корректный эндпоинт из старой версии: /subs/new-subscribtion
            // Формат: POST с JSON body {type: "company", value: "ИНН", sou: false}
            let endpoint = APIEndpoint.newSubscription(type: "company", value: inn, sou: false)
            guard let requestBody = endpoint.body as? NewSubscriptionRequest else {
                throw APIError.invalidURL
            }
            let _: SimpleResponse = try await apiService.request(
                endpoint: endpoint.path,
                method: endpoint.method,
                body: requestBody
            )
            
            isAdding = false
            successMessage = "Компания добавлена в мониторинг"
            
            // Очищаем форму
            searchQuery = ""
            selectedCompany = nil
            suggestions = []
            
            return true
        } catch {
            isAdding = false
            
            if let apiError = error as? APIError {
                switch apiError {
                case .httpError(let code):
                    if code == 400 {
                        errorMessage = "Компания уже добавлена в мониторинг"
                    } else {
                        errorMessage = "Не удалось добавить компанию"
                    }
                default:
                    errorMessage = "Ошибка при добавлении компании"
                }
            } else {
                errorMessage = "Ошибка при добавлении компании"
            }
            
            print("❌ Add company error: \(error)")
            return false
        }
    }
    
    /// Очистить выбранную компанию
    func clearSelection() {
        selectedCompany = nil
        searchQuery = ""
        suggestions = []
    }
}


