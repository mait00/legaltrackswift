//
//  String+Extensions.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

extension String {
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

