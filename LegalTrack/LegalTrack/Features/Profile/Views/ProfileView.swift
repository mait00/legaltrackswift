//
//  ProfileView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Страница профиля пользователя
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    @State private var showLogoutAlert = false
    @State private var showTariffs = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Шапка профиля
                        profileHeader
                            .padding(.bottom, AppSpacing.lg)
                        
                        // Карточка с информацией
                        VStack(spacing: AppSpacing.md) {
                            // Ошибка загрузки
                            if let error = viewModel.errorMessage, !isEditing {
                                errorCard(error: error)
                            }
                            
                            // Тип пользователя
                            if !isEditing {
                                userTypeCard
                            }
                            
                            // Основные данные
                            profileInfoCard
                            
                            // Статистика
                            if !isEditing {
                                statsCard
                            }
                            
                            // Кнопки действий
                            if isEditing {
                                saveButton
                            } else {
                                actionsCard
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, AppSpacing.xl)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if isEditing {
                                // Отмена редактирования - восстанавливаем данные
                                if let user = viewModel.user {
                                    viewModel.firstName = user.firstName ?? ""
                                    viewModel.lastName = user.lastName ?? ""
                                    viewModel.email = user.email ?? ""
                                }
                            }
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Отмена" : "Изменить")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("Вы уверены, что хотите выйти?")
            }
            .refreshable {
                await viewModel.loadProfile()
            }
            .navigationDestination(isPresented: $showTariffs) {
                TariffsView()
            }
        }
        .onDisappear {
            resetEditingState()
        }
        .task {
            await viewModel.loadProfile()
            appState.refreshUserProfile()
        }
    }

    private func resetEditingState() {
        guard isEditing else { return }
        if let user = viewModel.user {
            viewModel.firstName = user.firstName ?? ""
            viewModel.lastName = user.lastName ?? ""
            viewModel.email = user.email ?? ""
        }
        isEditing = false
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Аватар
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 15, y: 8)
                
                Text(viewModel.initials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Имя
            VStack(spacing: 4) {
                Text(viewModel.fullName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                if let email = viewModel.user?.email, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - User Type Card
    
    private var userTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Тип аккаунта")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: viewModel.userType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.userType.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Настройки уведомлений и функции зависят от типа")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .liquidGlassCard(padding: 0, material: .thinMaterial)
        }
    }
    
    // MARK: - Profile Info Card
    
    private var profileInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Личные данные")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if isEditing {
                    // Редактирование
                    ProfileEditField(
                        icon: "person",
                        title: "Имя",
                        text: $viewModel.firstName,
                        placeholder: "Введите имя"
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    ProfileEditField(
                        icon: "person",
                        title: "Фамилия",
                        text: $viewModel.lastName,
                        placeholder: "Введите фамилию"
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    ProfileEditField(
                        icon: "envelope",
                        title: "Email",
                        text: $viewModel.email,
                        placeholder: "Введите email",
                        keyboardType: .emailAddress
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    // Выбор типа пользователя
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "briefcase")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Тип аккаунта")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Picker("Тип", selection: $viewModel.userType) {
                                ForEach(ProfileViewModel.UserType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .liquidGlassSegmentedStyle()
                        }
                    }
                    .padding(16)
                    
                } else {
                    // Просмотр
                    ProfileInfoRow(
                        icon: "person",
                        title: "Имя",
                        value: viewModel.firstName.isEmpty ? "—" : viewModel.firstName
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    ProfileInfoRow(
                        icon: "person",
                        title: "Фамилия",
                        value: viewModel.lastName.isEmpty ? "—" : viewModel.lastName
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    ProfileInfoRow(
                        icon: "envelope",
                        title: "Email",
                        value: viewModel.email.isEmpty ? "—" : viewModel.email
                    )
                    
                    Divider().padding(.leading, 56)
                    
                    ProfileInfoRow(
                        icon: "phone",
                        title: "Телефон",
                        value: viewModel.phone.isEmpty ? "—" : viewModel.phone
                    )
                }
            }
            .liquidGlassCard(padding: 0, material: .thinMaterial)
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatBox(
                    icon: "folder.fill",
                    value: "—",
                    title: "Дел",
                    color: AppColors.primary
                )
                
                StatBox(
                    icon: "building.2.fill",
                    value: "—",
                    title: "Компаний",
                    color: AppColors.secondary
                )
                
                StatBox(
                    icon: "bell.fill",
                    value: "—",
                    title: "Уведомлений",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text(error)
                }
                .font(.system(size: 14))
                .foregroundColor(AppColors.error)
            }
            
            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text(success)
                }
                .font(.system(size: 14))
                .foregroundColor(AppColors.success)
            }
            
            Button {
                Task {
                    let success = await viewModel.saveProfile()
                    if success {
                        withAnimation(.spring(response: 0.3)) {
                            isEditing = false
                        }
                    }
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Сохранить изменения")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    viewModel.isFormValid
                        ? AppColors.primary
                        : AppColors.textSecondary
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.isFormValid || viewModel.isSaving)
        }
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Действия")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ProfileActionRow(
                    icon: "creditcard",
                    title: appState.isTariffActiveEffective ? "Тариф: активен" : "Тариф: бесплатный",
                    color: AppColors.secondary
                ) {
                    showTariffs = true
                }

                Divider().padding(.leading, 56)

                ProfileActionRow(
                    icon: "questionmark.circle",
                    title: "Помощь",
                    color: .blue
                ) {
                    // TODO: Открыть помощь
                }
                
                Divider().padding(.leading, 56)
                
                ProfileActionRow(
                    icon: "arrow.right.square",
                    title: "Выйти из аккаунта",
                    color: AppColors.error,
                    showChevron: false
                ) {
                    showLogoutAlert = true
                }
            }
            .liquidGlassCard(padding: 0, material: .thinMaterial)
        }
    }
    
    // MARK: - Error Card
    
    private func errorCard(error: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ошибка загрузки")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.loadProfile()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(AppSpacing.md)
        .liquidGlassCard(padding: 0, material: .thinMaterial)
    }
}

// MARK: - Supporting Views

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                
                Text(value)
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct ProfileEditField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let color: Color
    var showChevron: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(color == AppColors.error ? color : AppColors.textPrimary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(16)
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .liquidGlassCard(padding: 0, material: .ultraThinMaterial)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
