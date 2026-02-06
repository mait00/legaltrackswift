//
//  Date+Extensions.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

extension Date {
    /// Форматирование даты для отображения
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    /// Форматирование даты и времени
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
}

extension String {
    /// Преобразование строки в дату (поддерживает различные форматы ISO8601)
    func toDate() -> Date? {
        // Попытка с миллисекундами
        let formatterWithFrac = ISO8601DateFormatter()
        formatterWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFrac.date(from: self) {
            return date
        }
        
        // Попытка без миллисекунд
        let formatterNoFrac = ISO8601DateFormatter()
        formatterNoFrac.formatOptions = [.withInternetDateTime]
        if let date = formatterNoFrac.date(from: self) {
            return date
        }
        
        // Fallback с DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Формат с миллисекундами
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: self) {
            return date
        }
        
        // Формат с микросекундами
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        if let date = dateFormatter.date(from: self) {
            return date
        }
        
        // Простой формат
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: self) {
            return date
        }
        
        // ISO без часового пояса
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: self) {
            return date
        }
        
        return nil
    }
}

