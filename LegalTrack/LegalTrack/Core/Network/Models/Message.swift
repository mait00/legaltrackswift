//
//  Message.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Модель сообщения в чате
struct ChatMessage: Codable, Identifiable {
    let id: Int
    let text: String
    let datetime: String
    let isAdminAnswer: Bool
    let adminName: String?
    
    var isFromUser: Bool {
        !isAdminAnswer
    }
}

/// Ответ со списком сообщений
struct MessagesResponse: Codable {
    let messages: [ChatMessage]
}

/// Запрос на отправку сообщения
struct SendMessageRequest: Codable {
    let text: String
}

