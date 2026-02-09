//
//  Notification.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Тип уведомления
enum NotificationType: String, Codable {
    case company = "company"
    case caseType = "case"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationType(rawValue: rawValue) ?? .caseType
    }
}

/// Модель уведомления
struct AppNotification: Codable, Identifiable {
    let id: Int
    let textHeader: String
    let textSubHeader: String
    let text: String
    let type: NotificationType
    let meta: String
    let hasDocument: Bool
    let document: String?
    let caseId: Int
    let companyId: Int?
    let isSou: Bool
    
    /// Локальное состояние прочитанности (не с сервера)
    var isRead: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case textHeader = "text_header"
        case textSubHeader = "text_sub_header"
        case text
        case type
        case meta
        case hasDocument = "has_document"
        case document
        case caseId = "case"
        case companyId = "company"
        case isSou = "is_sou"
        // Локальное поле для кэша (сервер может не присылать)
        case isRead = "is_read"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        textHeader = try container.decode(String.self, forKey: .textHeader)
        textSubHeader = try container.decodeIfPresent(String.self, forKey: .textSubHeader) ?? ""
        text = try container.decode(String.self, forKey: .text)
        type = try container.decode(NotificationType.self, forKey: .type)
        meta = try container.decode(String.self, forKey: .meta)
        hasDocument = try container.decodeIfPresent(Bool.self, forKey: .hasDocument) ?? false
        document = try container.decodeIfPresent(String.self, forKey: .document)
        
        // case всегда присутствует в API
        caseId = try container.decode(Int.self, forKey: .caseId)
        
        // company может быть null для уведомлений типа "case"
        companyId = try container.decodeIfPresent(Int.self, forKey: .companyId)
        
        isSou = try container.decodeIfPresent(Bool.self, forKey: .isSou) ?? false
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
    }
    
    init(
        id: Int,
        textHeader: String,
        textSubHeader: String,
        text: String,
        type: NotificationType,
        meta: String,
        hasDocument: Bool,
        document: String?,
        caseId: Int,
        companyId: Int?,
        isSou: Bool,
        isRead: Bool = false
    ) {
        self.id = id
        self.textHeader = textHeader
        self.textSubHeader = textSubHeader
        self.text = text
        self.type = type
        self.meta = meta
        self.hasDocument = hasDocument
        self.document = document
        self.caseId = caseId
        self.companyId = companyId
        self.isSou = isSou
        self.isRead = isRead
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(textHeader, forKey: .textHeader)
        try container.encode(textSubHeader, forKey: .textSubHeader)
        try container.encode(text, forKey: .text)
        try container.encode(type, forKey: .type)
        try container.encode(meta, forKey: .meta)
        try container.encode(hasDocument, forKey: .hasDocument)
        try container.encodeIfPresent(document, forKey: .document)
        try container.encode(caseId, forKey: .caseId)
        try container.encodeIfPresent(companyId, forKey: .companyId)
        try container.encode(isSou, forKey: .isSou)
        try container.encode(isRead, forKey: .isRead)
    }
}

extension AppNotification {
    /// Стабильный ключ для сохранения прочитанности между перезагрузками.
    var readKey: String { "\(id)|\(caseId)|\(meta)" }
}

// Расширение для Hashable (для использования в NavigationLink)
extension AppNotification: Hashable {
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id && lhs.caseId == rhs.caseId && lhs.meta == rhs.meta
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(caseId)
        hasher.combine(meta)
    }
}

/// Ответ со списком уведомлений
struct NotificationsResponse: Codable {
    let message: String?
    let data: [AppNotification]
    let page: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case page
        case totalPages = "total_pages"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        
        // Парсим data - может быть массивом или отсутствовать
        if let dataArray = try? container.decode([AppNotification].self, forKey: .data) {
            data = dataArray
        } else {
            data = []
        }
        
        // page и totalPages могут отсутствовать в некоторых ответах
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        
        print("📬 [NotificationsResponse] Parsed: \(data.count) notifications, page \(page ?? 1)/\(totalPages ?? 1)")
    }
}
