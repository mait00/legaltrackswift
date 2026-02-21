//
//  AddCaseViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// ViewModel для добавления дела
@MainActor
final class AddCaseViewModel: ObservableObject {
    @Published var isAdding = false
    @Published var isAdded = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let apiService = APIService.shared
    
    /// Добавить дело в мониторинг
    /// Для АС: передается номер дела (например, А84-208/2026)
    /// Для СОЮ: передается URL дела с сайта суда
    func addCase(input: String, isSou: Bool) async {
        guard !input.isEmpty else { return }

        isAdding = true
        errorMessage = nil
        successMessage = nil

        let cleanedInput = input.trimmingCharacters(in: .whitespaces)
        
        print("🔍 [AddCase] Adding case: \(cleanedInput), isSou: \(isSou)")
        print("[AddCase] Перед отправкой: input=\(input), isSou=\(isSou)")

        do {
            // Используем корректный эндпоинт из старой версии: /subs/new-subscribtion
            // Формат: POST с JSON body {type: "case", value: "...", sou: boolean}
            let endpoint = APIEndpoint.addCase(value: cleanedInput, isSou: isSou)
            guard let requestBody = endpoint.body as? NewSubscriptionRequest else {
                throw APIError.invalidURL
            }
            
            print("📤 [AddCase] Endpoint: \(endpoint.path)")
            print("📤 [AddCase] Body: type=\(requestBody.type), value=\(requestBody.value), sou=\(requestBody.sou)")

            let response: AddCaseResponse = try await apiService.request(
                endpoint: endpoint.path,
                method: endpoint.method,
                body: requestBody
            )

            print("📥 [AddCase] Response: \(response)")

            isAdding = false

            if response.success == true || response.status == "success" || (response.message?.lowercased().contains("добавлен") == true) || response.data != nil {
                isAdded = true
                let baseMessage = response.message ?? "Дело успешно добавлено"
                successMessage = baseMessage + "\nИдёт поиск и добавление данных по делу. Это может занять несколько минут."
                print("✅ [AddCase] Case added successfully")
                NotificationCenter.default.post(name: .monitoringCasesDidChange, object: nil)
                
                // Очищаем кеш подписок для обновления списка дел
                CacheManager.shared.removeCache(forKey: "subscriptions")
            } else {
                let message = response.message ?? "Не удалось добавить дело"
                print("⚠️ [AddCase] Failed: \(message)")
                errorMessage = message
            }
        } catch {
            isAdding = false
            print("❌ [AddCase] Error: \(error)")

            if let apiError = error as? APIError {
                switch apiError {
                case .serverError(let message):
                    errorMessage = message
                case .networkError:
                    errorMessage = "Ошибка сети. Проверьте подключение к интернету"
                case .invalidResponse:
                    errorMessage = "Некорректный ответ сервера"
                case .httpError(let statusCode) where statusCode == 401:
                    errorMessage = "Требуется авторизация"
                case .httpError(let statusCode) where statusCode == 404:
                    errorMessage = isSou ? "Дело не найдено по указанной ссылке" : "Дело не найдено в системе арбитражных судов"
                case .httpError(let statusCode) where statusCode >= 500:
                    errorMessage = "Ошибка сервера. Попробуйте позже"
                default:
                    errorMessage = "Ошибка при добавлении дела"
                }
            } else {
                errorMessage = "Ошибка при добавлении дела: \(error.localizedDescription)"
            }
        }
    }
    
    /// Валидация ввода
    func validateInput(_ input: String, isSou: Bool) -> (isValid: Bool, errorMessage: String?) {
        let cleaned = input.trimmingCharacters(in: .whitespaces)
        
        if isSou {
            // Для СОЮ проверяем что это похоже на URL
            if cleaned.contains("http") || cleaned.contains(".ru") || cleaned.contains(".рф") {
                return (true, nil)
            } else {
                return (false, "Введите корректную ссылку с сайта суда")
            }
        } else {
            // Для АС: если пустая строка - ошибка, иначе всегда валидно
            if cleaned.isEmpty {
                return (false, "Введите данные")
            } else {
                return (true, nil)
            }
        }
    }
    
    private func parseDefendants(_ sideDf: CodableValue?) -> String? {
        guard let sideDf = sideDf else { return nil }
        
        if let stringValue = sideDf.stringValue, !stringValue.isEmpty {
            return stringValue
        }
        
        if let arrayValue = sideDf.arrayValue {
            let names = arrayValue.compactMap { $0.nameSide }
            return names.isEmpty ? nil : names.joined(separator: ", ")
        }
        
        return nil
    }
}

// MARK: - Models

struct AddCaseResponse: Codable {
    let message: String?
    let success: Bool?
    let status: String?
    let data: AddedCaseData?
    
    struct AddedCaseData: Codable {
        let id: Int?
        let value: String?
    }
}
