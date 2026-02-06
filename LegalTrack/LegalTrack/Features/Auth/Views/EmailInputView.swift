//
//  EmailInputView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран ввода email
struct EmailInputView: View {
    @Binding var email: String
    let onContinue: () -> Void
    
    @FocusState private var isEmailFocused: Bool
    
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
                
                Text("Введите email")
                    .font(.system(size: AppTypography.headline))
                    .foregroundColor(AppColors.textOnDark.opacity(0.8))
            }
            
            VStack(spacing: AppSpacing.lg) {
                TextField("example@mail.ru", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .font(.system(size: AppTypography.headline))
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                            .stroke(isEmailFocused ? AppColors.secondary : AppColors.border, lineWidth: 2)
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .onChange(of: email) { oldValue, newValue in
                        // Приводим к нижнему регистру и убираем пробелы
                        email = newValue.lowercased().trimmingCharacters(in: .whitespaces)
                    }
                
                PrimaryButton(
                    title: "Продолжить",
                    action: onContinue,
                    isEnabled: isValidEmail(email)
                )
                .padding(.horizontal, AppSpacing.md)
                
                if !email.isEmpty && !isValidEmail(email) {
                    Text("Введите корректный email адрес")
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
                isEmailFocused = true
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        
        // Проверка на двойные точки, точки в начале/конце
        if trimmed.contains("..") || trimmed.hasPrefix(".") || trimmed.hasSuffix(".") {
            return false
        }
        
        // Базовая проверка формата email
        let emailRegex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: trimmed)
    }
}

#Preview {
    EmailInputView(email: .constant("")) {}
}








