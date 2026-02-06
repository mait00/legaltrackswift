//
//  RussianPhoneTextField.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Компонент для ввода российского номера телефона с автоматическим форматированием
struct RussianPhoneTextField: View {
    @Binding var phoneNumber: String
    let placeholder: String
    var icon: String = "phone"
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? AppColors.secondary : .white.opacity(0.4))
                .frame(width: 24)
            
            HStack(spacing: 4) {
                // Префикс +7 (не редактируемый)
                Text("+7")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 24)
                
                // Поле ввода (только цифры)
                TextField("", text: Binding(
                    get: { phoneNumber },
                    set: { newValue in
                        formatPhoneNumber(newValue)
                    }
                ), prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused 
                                ? LinearGradient(
                                    colors: [AppColors.secondary.opacity(0.6), AppColors.secondary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: isFocused ? AppColors.secondary.opacity(0.2) : .clear, radius: 8, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
    
    /// Форматирует номер телефона в формат: (999) 123-45-67
    private func formatPhoneNumber(_ value: String) {
        // Удаляем все нецифровые символы
        let cleaned = value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Ограничиваем до 10 цифр (без +7)
        let limited = String(cleaned.prefix(10))
        
        // Форматируем номер
        var formatted = ""
        if !limited.isEmpty {
            // Первые 3 цифры - код оператора
            let startIndex = limited.startIndex
            let index3 = limited.index(startIndex, offsetBy: min(3, limited.count))
            formatted = "(\(limited[startIndex..<index3])"
            
            if limited.count > 3 {
                // Следующие 3 цифры
                let index6 = limited.index(index3, offsetBy: min(3, limited.count - 3))
                formatted += ") \(limited[index3..<index6])"
                
                if limited.count > 6 {
                    // Следующие 2 цифры
                    let index8 = limited.index(index6, offsetBy: min(2, limited.count - 6))
                    formatted += "-\(limited[index6..<index8])"
                    
                    if limited.count > 8 {
                        // Последние 2 цифры
                        let endIndex = limited.index(index8, offsetBy: min(2, limited.count - 8))
                        formatted += "-\(limited[index8..<endIndex])"
                    }
                }
            } else {
                formatted += ")"
            }
        }
        
        // Обновляем значение
        phoneNumber = formatted
    }
    
    /// Возвращает очищенный номер телефона для отправки на сервер (формат: 79991234567)
    var cleanedPhoneNumber: String {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Если 10 цифр, добавляем 7 в начало
        if cleaned.count == 10 {
            return "7" + cleaned
        }
        // Если уже начинается с 7 или 8 и 11 цифр
        if (cleaned.hasPrefix("7") || cleaned.hasPrefix("8")) && cleaned.count == 11 {
            return cleaned.hasPrefix("8") ? "7" + String(cleaned.dropFirst()) : cleaned
        }
        return cleaned
    }
    
    /// Проверяет валидность номера телефона
    var isValid: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count == 10
    }
}

#Preview {
    ZStack {
        Color.black
        RussianPhoneTextField(
            phoneNumber: .constant(""),
            placeholder: "(999) 123-45-67"
        )
        .padding()
    }
}
