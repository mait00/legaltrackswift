//
//  PrimaryButton.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Основная кнопка приложения
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: AppTypography.headline, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.UI.buttonHeight)
            .background(
                isEnabled && !isLoading
                    ? AppColors.secondary
                    : AppColors.textSecondary
            )
            .cornerRadius(AppConstants.UI.cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Войти", action: {})
        PrimaryButton(title: "Загрузка...", action: {}, isLoading: true)
        PrimaryButton(title: "Неактивна", action: {}, isEnabled: false)
    }
    .padding()
}

