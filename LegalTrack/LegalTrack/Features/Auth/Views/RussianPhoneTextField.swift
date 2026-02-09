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
                .foregroundColor(isFocused ? AppColors.secondary : AppColors.textSecondary.opacity(0.8))
                .frame(width: 24)
            
            HStack(spacing: 4) {
                // Префикс +7 (не редактируемый)
                Text("+7")
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)
                
                // Поле ввода (только цифры)
                TextField("", text: Binding(
                    get: { phoneNumber },
                    set: { newValue in
                        formatPhoneNumber(newValue)
                    }
                ), prompt: Text(placeholder).foregroundColor(AppColors.textSecondary.opacity(0.7)))
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        // Avoid heavy implicit animations on focus which can stall the main thread on older devices.
        .transaction { $0.animation = nil }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused 
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [AppColors.secondary.opacity(0.6), AppColors.secondary.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(AppColors.border.opacity(0.7)),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }
    
    // MARK: - Normalization

    /// Оставляет только 10 цифр номера РФ без префикса страны.
    /// Поддерживает вставку в виде: `+7...`, `7...`, `8...`, со скобками/пробелами/дефисами.
    static func normalizeLocal10Digits(from input: String) -> String {
        var digits = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // Если вставили полный номер 11 цифр с 7/8 в начале, отбрасываем префикс.
        if digits.count == 11, digits.hasPrefix("7") || digits.hasPrefix("8") {
            digits = String(digits.dropFirst())
        }

        // Если вставили что-то длиннее (например +7 9.. с мусором) - берём последние 10 цифр.
        if digits.count > 10 {
            digits = String(digits.suffix(10))
        }

        return digits
    }

    /// Возвращает номер для отправки на сервер в формате `7XXXXXXXXXX` (11 цифр) или пустую строку.
    static func normalizeE164RuDigits(from input: String) -> String {
        let local10 = normalizeLocal10Digits(from: input)
        guard local10.count == 10 else { return "" }
        return "7" + local10
    }

    /// Форматирует 10 цифр в формат: (999) 123-45-67
    static func formatLocal10Digits(_ local10: String) -> String {
        let limited = String(local10.prefix(10))
        guard !limited.isEmpty else { return "" }

        var formatted = ""
        let startIndex = limited.startIndex
        let index3 = limited.index(startIndex, offsetBy: min(3, limited.count))
        formatted = "(\(limited[startIndex..<index3])"

        if limited.count > 3 {
            let index6 = limited.index(index3, offsetBy: min(3, limited.count - 3))
            formatted += ") \(limited[index3..<index6])"

            if limited.count > 6 {
                let index8 = limited.index(index6, offsetBy: min(2, limited.count - 6))
                formatted += "-\(limited[index6..<index8])"

                if limited.count > 8 {
                    let endIndex = limited.index(index8, offsetBy: min(2, limited.count - 8))
                    formatted += "-\(limited[index8..<endIndex])"
                }
            }
        } else {
            formatted += ")"
        }

        return formatted
    }

    /// Применяет нормализацию и форматирование к тексту из TextField.
    private func formatPhoneNumber(_ value: String) {
        let local10 = Self.normalizeLocal10Digits(from: value)
        phoneNumber = Self.formatLocal10Digits(local10)
    }
    
    /// Возвращает очищенный номер телефона для отправки на сервер (формат: 79991234567)
    var cleanedPhoneNumber: String {
        Self.normalizeE164RuDigits(from: phoneNumber)
    }
    
    /// Проверяет валидность номера телефона
    var isValid: Bool {
        Self.normalizeLocal10Digits(from: phoneNumber).count == 10
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
