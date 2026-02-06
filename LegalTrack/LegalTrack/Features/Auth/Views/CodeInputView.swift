//
//  CodeInputView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран ввода SMS-кода или кода из email
struct CodeInputView: View {
    let identifier: String // Телефон или email
    let isEmail: Bool // true если email, false если телефон
    let onVerify: (String) -> Void
    
    @State private var code: String = ""
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            VStack(spacing: AppSpacing.md) {
                // Заголовок как в оригинале: "В" белым + "ход" оранжевым
                HStack(spacing: 0) {
                    Text("В")
                        .foregroundColor(AppColors.textOnDark)
                    Text("ход")
                        .foregroundColor(AppColors.secondary)
                }
                .font(.system(size: AppTypography.title1, weight: .semibold))
                .padding(.bottom, AppSpacing.lg)
                
                Text(isEmail ? "Код отправлен на \(identifier)" : "Код отправлен на \(identifier)")
                    .font(.system(size: AppTypography.body))
                    .foregroundColor(AppColors.textOnDark.opacity(0.8))
            }
            
            VStack(spacing: AppSpacing.lg) {
                // Поле ввода кода - как в оригинале
                TextField("СМС код", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFocused)
                    .font(.system(size: AppTypography.headline, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, AppSpacing.xl)
                    .onChange(of: code) { oldValue, newValue in
                        // Ограничиваем ввод только цифрами
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            code = filtered
                        }
                        // Ограничиваем длину до 6 символов
                        if code.count > 6 {
                            code = String(code.prefix(6))
                        }
                    }
                    .onSubmit {
                        if code.count >= 4 {
                            onVerify(code)
                        }
                    }
                
                // Кнопка подтверждения
                PrimaryButton(
                    title: "Далее",
                    action: { onVerify(code) },
                    isLoading: false,
                    isEnabled: code.count >= 4
                )
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                
                if code.count > 0 && code.count < 4 {
                    Text(isEmail ? "Введите код из письма" : "Введите код из СМС")
                        .font(.system(size: AppTypography.caption1))
                        .foregroundColor(AppColors.textOnDark.opacity(0.7))
                        .padding(.top, AppSpacing.sm)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundDark) // Темный фон как в оригинале
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFocused = true
            }
        }
    }
}

#Preview {
    CodeInputView(identifier: "+7 (999) 123-45-67", isEmail: false) { _ in }
}

