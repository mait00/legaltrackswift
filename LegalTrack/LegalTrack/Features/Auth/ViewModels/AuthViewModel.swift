//
//  AuthViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    /// Запросить код подтверждения по телефону
    func requestCode(phone: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let response: CodeResponse = try await apiService.request(
                    endpoint: APIEndpoint.getCode(phone: phone).path,
                    method: .get
                )
                
                print("📱 Request code response: success=\(response.success ?? false), status=\(response.status ?? "nil"), message=\(response.message ?? "nil")")
                
                isLoading = false
                
                // Проверяем message на успешную отправку
                let message = (response.message ?? response.data?.message ?? "").lowercased()
                let hasSuccessMessage = message.contains("успешно") || 
                                        message.contains("отправлен") ||
                                        message.contains("отправлен")
                let hasExplicitError = message.contains("ошибка") || 
                                       message.contains("error") || 
                                       message.contains("неверный") || 
                                       message.contains("invalid") ||
                                       message.contains("не удалось")
                
                // Считаем успехом, если success == true ИЛИ status == "success" ИЛИ есть сообщение об успешной отправке
                let success = (response.success == true || 
                              response.status == "success" || 
                              response.data?.success == true ||
                              hasSuccessMessage) && !hasExplicitError
                
                print("📱 Success determined: \(success) (hasSuccessMessage: \(hasSuccessMessage), hasExplicitError: \(hasExplicitError), message: '\(message)')")
                
                // Если успех - показываем экран ввода кода
                if success {
                    print("✅ Code request successful, showing code input screen")
                    await MainActor.run {
                        completion(true)
                    }
                } else {
                    let errorMsg = response.message ?? response.data?.message ?? "Не удалось отправить код"
                    errorMessage = errorMsg
                    print("❌ Request code failed: \(errorMsg)")
                    await MainActor.run {
                        completion(false)
                    }
                }
            } catch {
                isLoading = false
                print("❌ Request code error: \(error)")
                errorMessage = error.localizedDescription
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    /// Запросить код подтверждения по email
    func requestCode(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Email передается в тот же эндпоинт, что и телефон, но как параметр phone
        Task {
            do {
                let response: CodeResponse = try await apiService.request(
                    endpoint: APIEndpoint.getCode(phone: email).path,
                    method: .get
                )
                
                isLoading = false
                let success = response.success == true || response.status == "success" || response.data?.success == true
                if !success {
                    errorMessage = response.message ?? response.data?.message ?? "Не удалось отправить код"
                }
                await MainActor.run {
                    completion(success)
                }
            } catch {
                isLoading = false
                print("❌ Request email code error: \(error)")
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Ошибка отправки email. Проверьте интернет соединение"
                    }
                } else {
                    errorMessage = "Ошибка отправки email. Проверьте интернет соединение"
                }
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    /// Подтвердить код по телефону
    func verifyCode(phone: String, code: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response: AuthResponse = try await apiService.request(
                    endpoint: APIEndpoint.sendCode(phone: phone, code: code).path,
                    method: .get
                )
                
                // Получаем токен из ответа
                let token = response.authToken
                
                if let token = token, !token.isEmpty {
                    apiService.setToken(token)
                    isLoading = false
                    completion(true, token)
                } else {
                    isLoading = false
                    errorMessage = response.message ?? "Неверный код подтверждения"
                    completion(false, nil)
                }
            } catch {
                isLoading = false
                print("❌ Verify code error: \(error)")
                errorMessage = error.localizedDescription
                completion(false, nil)
            }
        }
    }
    
    /// Подтвердить код по email
    func verifyCode(email: String, code: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Email передается в тот же эндпоинт, что и телефон, но как параметр phone
        Task {
            do {
                let response: AuthResponse = try await apiService.request(
                    endpoint: APIEndpoint.sendCode(phone: email, code: code).path,
                    method: .get
                )
                
                // Получаем токен из ответа
                let token = response.authToken
                
                if let token = token, !token.isEmpty {
                    apiService.setToken(token)
                    isLoading = false
                    completion(true, token)
                } else {
                    isLoading = false
                    errorMessage = response.message ?? "Неверный код подтверждения"
                    completion(false, nil)
                }
            } catch {
                isLoading = false
                print("❌ Verify email code error: \(error)")
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Ошибка проверки кода. Проверьте интернет соединение"
                    }
                } else {
                    errorMessage = "Ошибка проверки кода. Проверьте интернет соединение"
                }
                completion(false, nil)
            }
        }
    }
}

