//
//  AddCompanyView.swift
//  LegalTrack
//
//  Экран добавления компании с DaData автодополнением
//

import SwiftUI

/// Экран добавления новой компании в мониторинг
struct AddCompanyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddCompanyViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
                                
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Добавить компанию")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Введите ИНН или название компании")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 16)
                        
                        // Поле поиска
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Поиск компании")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(AppColors.textSecondary)
                                    .font(.system(size: 18))
                                
                                TextField("ИНН или название", text: $viewModel.searchQuery)
                                    .focused($isSearchFocused)
                                    .textContentType(.organizationName)
                                    .autocorrectionDisabled()
                                    .onChange(of: viewModel.searchQuery) { _, newValue in
                                        viewModel.searchCompanies()
                                    }
                                
                                if !viewModel.searchQuery.isEmpty {
                                    Button {
                                        viewModel.clearSelection()
                                        isSearchFocused = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                                    .stroke(isSearchFocused ? AppColors.primary : Color.clear, lineWidth: 2)
                            )
                        }
                        .liquidGlassCard()
                        
                        // Индикатор загрузки
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Поиск компаний...")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding()
                            .liquidGlassCard()
                        }
                        
                        // Предложения DaData
                        if !viewModel.suggestions.isEmpty && viewModel.selectedCompany == nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Найденные компании")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                ForEach(viewModel.suggestions) { company in
                                    CompanySuggestionCard(company: company) {
                                        viewModel.selectCompany(company)
                                        isSearchFocused = false
                                    }
                                }
                            }
                            .liquidGlassCard()
                        }
                        
                        // Выбранная компания
                        if let company = viewModel.selectedCompany {
                            SelectedCompanyCard(company: company) {
                                viewModel.clearSelection()
                            }
                        }
                        
                        // Сообщения об ошибке/успехе
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius))
                        }
                        
                        if let success = viewModel.successMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(success)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Добавить компанию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.addCompany()
                            if success {
                                // Закрываем через небольшую задержку, чтобы показать сообщение об успехе
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isAdding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Добавить")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.selectedCompany == nil || viewModel.isAdding)
                }
            }
        }
    }
}

/// Карточка предложения компании
struct CompanySuggestionCard: View {
    let company: DaDataCompany
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(company.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let inn = company.inn {
                            Text("ИНН: \(inn)")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                let address = company.addressText
                if address != "Адрес не указан" {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(address)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(spacing: 12) {
                    Label(company.statusText, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(company.state?.status == "ACTIVE" ? .green : .orange)
                }
            }
            .padding(16)
            .background(Material.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// Карточка выбранной компании
struct SelectedCompanyCard: View {
    let company: DaDataCompany
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Выбранная компания")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(company.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let inn = company.inn {
                            Text("ИНН: \(inn)")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                
                Divider()
                
                let address = company.addressText
                if address != "Адрес не указан" {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.primary)
                        Text(address)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(spacing: 16) {
                    if let ogrn = company.ogrn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ОГРН")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                            Text(ogrn)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Статус")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textSecondary)
                        Text(company.statusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(company.state?.status == "ACTIVE" ? .green : .orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    AddCompanyView()
}
