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
    private let decodeQueue = DispatchQueue(label: "APIService.decode", qos: .userInitiated)
    
    private init() {
        self.baseURL = AppConstants.API.baseURL
        let configuration = URLSessionConfiguration.default
        // Fail fast on unstable mobile networks to avoid long UI hangs.
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = min(AppConstants.API.timeout, 12)
        configuration.timeoutIntervalForResource = min(AppConstants.API.timeout, 20)
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
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
        let data = try await requestData(endpoint: endpoint, method: method, body: body)
        return try await decodeOnBackground(T.self, from: data)
    }

    /// Выполнить запрос и вернуть сырые данные ответа
    func requestData(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> Data {
        let request = try buildRequest(endpoint: endpoint, method: method, body: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            debugLog("🌐 API response status: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? endpoint)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(message: errorResponse.message ?? "Ошибка сервера")
                }
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }

            return data
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw APIError.networkError("Превышено время ожидания. Проверьте интернет соединение")
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                throw APIError.networkError("Нет соединения с сервером. Проверьте интернет")
            case .cancelled:
                throw CancellationError()
            default:
                throw APIError.networkError(urlError.localizedDescription)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) throws -> URLRequest {
        let urlString = "\(baseURL)\(endpoint)"
        debugLog("🌐 API request: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = min(AppConstants.API.timeout, 12)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError
            }
        }

        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            debugLog("❌ Decoding failed for \(String(describing: T.self)): \(error.localizedDescription)")
            throw APIError.decodingError
        }
    }

    private func decodeOnBackground<T: Decodable>(_ type: T.Type, from data: Data) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            decodeQueue.async {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    let value = try decoder.decode(T.self, from: data)
                    continuation.resume(returning: value)
                } catch {
                    #if DEBUG
                    print("❌ Decoding failed for \(String(describing: T.self)): \(error.localizedDescription)")
                    #endif
                    continuation.resume(throwing: APIError.decodingError)
                }
            }
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
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
