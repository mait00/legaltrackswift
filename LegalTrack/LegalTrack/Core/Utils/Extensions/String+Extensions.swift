//
//  String+Extensions.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

extension String {
    /// Trim whitespace/newlines; returns nil if the result is empty.
    func trimmedNonEmpty() -> String? {
        let v = trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    /// Best-effort casing for person names (ru/en): trims, collapses spaces,
    /// and capitalizes each word/hyphen-part.
    func personNameCased(locale: Locale = Locale(identifier: "ru_RU")) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        // Collapse multiple spaces.
        let collapsed = trimmed
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        func capPart(_ s: Substring) -> String {
            let str = String(s).lowercased(with: locale)
            guard let first = str.first else { return "" }
            return String(first).uppercased(with: locale) + str.dropFirst()
        }

        let words = collapsed.split(separator: " ")
        let casedWords = words.map { word -> String in
            // Preserve hyphenated parts: "иван-иванов" -> "Иван-Иванов"
            let parts = word.split(separator: "-", omittingEmptySubsequences: false)
            return parts.map(capPart).joined(separator: "-")
        }
        return casedWords.joined(separator: " ")
    }

    /// Форматирование номера телефона
    func formattedPhone() -> String {
        let cleaned = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if cleaned.count == 11 && cleaned.hasPrefix("7") {
            let index1 = cleaned.index(cleaned.startIndex, offsetBy: 1)
            let index4 = cleaned.index(cleaned.startIndex, offsetBy: 4)
            let index7 = cleaned.index(cleaned.startIndex, offsetBy: 7)
            let index9 = cleaned.index(cleaned.startIndex, offsetBy: 9)
            
            return "+7 (\(cleaned[index1..<index4])) \(cleaned[index4..<index7])-\(cleaned[index7..<index9])-\(cleaned[index9...])"
        }
        
        return self
    }
    
    /// Проверка валидности номера телефона
    func isValidPhone() -> Bool {
        let cleaned = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count >= 10
    }
}
