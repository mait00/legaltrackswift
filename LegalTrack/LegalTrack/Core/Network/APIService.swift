//
//  APIService.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Основной сервис для работы с API
final class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    
    private init() {
        self.baseURL = AppConstants.API.baseURL
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConstants.API.timeout
        configuration.timeoutIntervalForResource = AppConstants.API.timeout
        self.session = URLSession(configuration: configuration)
        
        // Загружаем токен из Keychain
        self.authToken = KeychainManager.shared.get(forKey: AppConstants.StorageKeys.authToken)
    }
    
    /// Установить токен авторизации
    func setToken(_ token: String?) {
        self.authToken = token
        if let token = token {
            _ = KeychainManager.shared.save(token, forKey: AppConstants.StorageKeys.authToken)
        } else {
            _ = KeychainManager.shared.delete(forKey: AppConstants.StorageKeys.authToken)
        }
    }
    
    /// Выполнить запрос
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        // Обрабатываем URL с query параметрами
        let urlString = "\(baseURL)\(endpoint)"
        print("🌐 API Request: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Добавляем токен авторизации если есть
        if let token = authToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token: \(token.prefix(20))...")
        } else {
            print("⚠️ No auth token available")
        }
        
        // Добавляем тело запроса если есть
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Логируем ответ для отладки
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Пытаемся декодировать ошибку
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(message: errorResponse.message ?? "Ошибка сервера")
                }
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Логируем полный JSON перед декодированием
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Full JSON response: \(responseString)")
                }
                
                let result = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response as \(String(describing: T.self))")
                return result
            } catch let decodingError {
                print("❌ Decoding error: \(decodingError)")
                print("❌ Error details: \(decodingError.localizedDescription)")
                
                // Пытаемся вывести сырые данные для отладки
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Raw response (first 1000 chars): \(String(responseString.prefix(1000)))")
                }
                
                // Пытаемся декодировать как словарь для отладки
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📦 JSON structure: \(json.keys.joined(separator: ", "))")
                }
                
                throw APIError.decodingError
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Error Response
struct APIErrorResponse: Codable {
    let message: String?
    let error: String?
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingError
    case decodingError
    case httpError(statusCode: Int)
    case networkError(String)
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .httpError(let code):
            return "HTTP ошибка: \(code)"
        case .networkError(let message):
            return "Сетевая ошибка: \(message)"
        case .serverError(let message):
            return message
        }
    }
}

