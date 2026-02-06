//
//  User.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Модель пользователя
struct User: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let type: String?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

/// Ответ на запрос кода
struct CodeResponse: Codable {
    let success: Bool?
    let message: String?
    let status: String?
    let data: CodeData?
    
    struct CodeData: Codable {
        let success: Bool?
        let message: String?
    }
}

/// Ответ на отправку кода
struct AuthResponse: Codable {
    let token: String?
    let data: AuthData?
    let message: String?
    let status: String?
    
    struct AuthData: Codable {
        let token: String?
        let user: User?
    }
    
    // Получить токен из любого места в ответе
    var authToken: String? {
        return token ?? data?.token
    }
}

/// Запрос на получение кода
struct GetCodeRequest: Codable {
    let phone: String
}

/// Запрос на отправку кода
struct SendCodeRequest: Codable {
    let phone: String
    let code: String
}

/// Запрос на редактирование профиля
struct EditProfilePayload: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let type: String
}

