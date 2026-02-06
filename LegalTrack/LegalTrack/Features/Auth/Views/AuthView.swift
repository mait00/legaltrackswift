//
//  AuthView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Главный экран авторизации - современный минималистичный дизайн
struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var currentStep: AuthStep = .input
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var code = ""
    @State private var authMethod: AuthMethod = .email
    @State private var isAnimating = false
    
    enum AuthStep {
        case input
        case code
    }
    
    enum AuthMethod {
        case phone
        case email
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Liquid Glass фон
                LiquidGlassBackground()
                
                // Основной контент
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Лого и заголовок
                    VStack(spacing: 16) {
                        // Логотип
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .shadow(color: AppColors.secondary.opacity(0.5), radius: 20, y: 10)
                            .padding(.bottom, 8)
                            .opacity(isAnimating ? 1.0 : 0)
                        
                        Image("ucni_legaltrack")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 36)
                            .padding(.bottom, 2)
                            .opacity(isAnimating ? 1.0 : 0)
                        
                        Text(currentStep == .input ? "Вход в систему" : "Подтверждение")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(isAnimating ? 1.0 : 0)
                    }
                    .padding(.bottom, 48)
                    
                    // Форма ввода
                    VStack(spacing: 20) {
                        if currentStep == .input {
                            inputView
                        } else {
                            codeView
                        }
                    }
                    .padding(.horizontal, 32)
                    .opacity(isAnimating ? 1.0 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .frame(maxWidth: 500) // Ограничение ширины для iPad
                    
                    Spacer()
                    
                    // Переключатель метода
                    if currentStep == .input {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                authMethod = authMethod == .email ? .phone : .email
                                phoneNumber = ""
                                email = ""
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: authMethod == .email ? "phone" : "envelope")
                                    .font(.system(size: 14))
                                Text(authMethod == .email ? "Войти по телефону" : "Войти по email")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 12)
                        }
                        .opacity(isAnimating ? 1.0 : 0)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                currentStep = .input
                                code = ""
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14))
                                Text("Изменить \(authMethod == .email ? "email" : "номер")")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 12)
                        }
                    }
                    
                    // Отступ для безопасной зоны
                    Spacer()
                        .frame(height: 20)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Input View
    
    @ViewBuilder
    private var inputView: some View {
        VStack(spacing: 16) {
            if authMethod == .email {
                // Email поле
                AuthTextField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
            } else {
                // Телефон поле с автоматическим форматированием
                RussianPhoneTextField(
                    phoneNumber: $phoneNumber,
                    placeholder: "(999) 123-45-67"
                )
            }
            
            // Ошибка
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 14))
                    Text(error)
                        .font(.system(size: 13))
                }
                .foregroundColor(AppColors.error)
                .padding(.horizontal, 4)
            }
            
            // Кнопка продолжить
            AuthButton(
                title: "Получить код",
                isLoading: viewModel.isLoading,
                isEnabled: authMethod == .email ? isValidEmail(email) : isPhoneValid
            ) {
                requestCode()
            }
        }
    }
    
    // MARK: - Code View
    
    @ViewBuilder
    private var codeView: some View {
        VStack(spacing: 16) {
            // Информация
            VStack(spacing: 8) {
                Text("Код отправлен на")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(authMethod == .email ? email : formattedPhoneForDisplay)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)
            
            // Поле кода
            AuthTextField(
                icon: "key",
                placeholder: "Введите код",
                text: $code,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
            .onChange(of: code) { oldValue, newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    code = filtered
                }
                if code.count > 6 {
                    code = String(code.prefix(6))
                }
            }
            
            // Ошибка
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 14))
                    Text(error)
                        .font(.system(size: 13))
                }
                .foregroundColor(AppColors.error)
                .padding(.horizontal, 4)
            }
            
            // Кнопка войти
            AuthButton(
                title: "Войти",
                isLoading: viewModel.isLoading,
                isEnabled: code.count >= 4
            ) {
                verifyCode()
            }
        }
    }
    
    // MARK: - Actions
    
    private func requestCode() {
        withAnimation(.spring(response: 0.3)) {
            currentStep = .code
        }
        
        if authMethod == .email {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
            viewModel.requestCode(email: trimmedEmail) { _ in }
        } else {
            // Используем очищенный номер из RussianPhoneTextField
            let finalPhone = cleanedPhoneNumber
            viewModel.requestCode(phone: finalPhone) { _ in }
        }
    }
    
    private func verifyCode() {
        if authMethod == .email {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
            viewModel.verifyCode(email: trimmedEmail, code: code) { success, token in
                if success, let token = token {
                    appState.authenticate(with: token)
                }
            }
        } else {
            // Используем очищенный номер из RussianPhoneTextField
            let finalPhone = cleanedPhoneNumber
            viewModel.verifyCode(phone: finalPhone, code: code) { success, token in
                if success, let token = token {
                    appState.authenticate(with: token)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains("..") || trimmed.hasPrefix(".") || trimmed.hasSuffix(".") {
            return false
        }
        let emailRegex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: trimmed)
    }
    
    // MARK: - Computed Properties
    
    /// Проверяет валидность номера телефона
    private var isPhoneValid: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count == 10
    }
    
    /// Возвращает очищенный номер телефона для отправки на сервер
    private var cleanedPhoneNumber: String {
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
    
    /// Форматированный номер для отображения
    private var formattedPhoneForDisplay: String {
        if phoneNumber.isEmpty {
            return ""
        }
        return "+7 " + phoneNumber
    }
}

// MARK: - Auth TextField

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? AppColors.secondary : .white.opacity(0.4))
                .frame(width: 24)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 17))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($isFocused)
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
}

// MARK: - Auth Button

struct AuthButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled && !isLoading {
                        LinearGradient(
                            colors: [AppColors.secondary, AppColors.secondary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isEnabled ? AppColors.secondary.opacity(0.4) : .clear, radius: 12, y: 6)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}
