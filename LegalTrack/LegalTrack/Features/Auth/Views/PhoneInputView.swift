//
//  PhoneInputView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран ввода номера телефона
struct PhoneInputView: View {
    @Binding var phoneNumber: String
    let onContinue: () -> Void
    
    @FocusState private var isPhoneFocused: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            VStack(spacing: AppSpacing.md) {
                // Заголовок как в оригинале: "L" оранжевым + "egal.Track" белым
                HStack(spacing: 0) {
                    Text("L")
                        .foregroundColor(AppColors.secondary)
                    Text("egal.Track")
                        .foregroundColor(AppColors.textOnDark)
                }
                .font(.system(size: AppTypography.title1, weight: .semibold))
                .padding(.bottom, AppSpacing.sm)
                
                Text("Введите номер телефона")
                    .font(.system(size: AppTypography.headline))
                    .foregroundColor(AppColors.textOnDark.opacity(0.8))
            }
            
            VStack(spacing: AppSpacing.lg) {
                TextField("+7 (999) 123-45-67", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($isPhoneFocused)
                    .font(.system(size: AppTypography.headline))
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                            .stroke(isPhoneFocused ? AppColors.secondary : AppColors.border, lineWidth: 2)
                    )
                    .padding(.horizontal, AppSpacing.md)
                
                PrimaryButton(
                    title: "Продолжить",
                    action: onContinue,
                    isEnabled: isValidPhone(phoneNumber)
                )
                .padding(.horizontal, AppSpacing.md)
                
                if !phoneNumber.isEmpty && !isValidPhone(phoneNumber) {
                    Text("Введите корректный номер телефона")
                        .font(.system(size: AppTypography.caption1))
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal, AppSpacing.md)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundDark) // Темный фон как в оригинале
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPhoneFocused = true
            }
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let cleaned = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Проверяем что номер начинается с 7 или 8 и имеет 11 цифр, или просто 10 цифр
        if cleaned.hasPrefix("7") || cleaned.hasPrefix("8") {
            return cleaned.count == 11
        }
        return cleaned.count >= 10 && cleaned.count <= 11
    }
    
    // Форматируем номер для отправки (только цифры)
    var cleanedPhone: String {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Если начинается с 8, заменяем на 7
        if cleaned.hasPrefix("8") && cleaned.count == 11 {
            return "7" + String(cleaned.dropFirst())
        }
        // Если 10 цифр, добавляем 7
        if cleaned.count == 10 {
            return "7" + cleaned
        }
        return cleaned
    }
}

#Preview {
    PhoneInputView(phoneNumber: .constant("")) {}
}

