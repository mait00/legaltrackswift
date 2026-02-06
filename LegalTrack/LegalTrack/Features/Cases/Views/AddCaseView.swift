//
//  AddCaseView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран добавления нового дела в мониторинг
struct AddCaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddCaseViewModel()
    @State private var inputText = ""
    @State private var selectedCourtType: CourtType = .arbitration
    @FocusState private var isInputFocused: Bool
    
    enum CourtType: String, CaseIterable {
        case arbitration = "Арбитражные суды"
        case general = "Суды общей юрисдикции"
        
        var isSou: Bool {
            self == .general
        }
        
        var shortName: String {
            switch self {
            case .arbitration: return "АС"
            case .general: return "СОЮ"
            }
        }
        
        var placeholder: String {
            switch self {
            case .arbitration: return "А84-208/2026"
            case .general: return "https://..."
            }
        }
        
        var inputLabel: String {
            switch self {
            case .arbitration: return "НОМЕР ДЕЛА"
            case .general: return "ССЫЛКА НА ДЕЛО"
            }
        }
        
        var helpText: String {
            switch self {
            case .arbitration: return "Введите номер дела, например: А84-208/2026"
            case .general: return "Скопируйте ссылку на дело с сайта суда"
            }
        }
        
        var icon: String {
            switch self {
            case .arbitration: return "building.columns.fill"
            case .general: return "person.3.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
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
                                
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Добавить дело")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Введите номер дела для добавления в мониторинг")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 16)
                        
                        // Выбор типа суда
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ТИП СУДА")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 12) {
                                ForEach(CourtType.allCases, id: \.self) { type in
                                    CourtTypeCard(
                                        type: type,
                                        isSelected: selectedCourtType == type
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCourtType = type
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Поле ввода
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedCourtType.inputLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 12) {
                                Image(systemName: selectedCourtType == .arbitration ? "doc.text.magnifyingglass" : "link")
                                    .font(.system(size: 20))
                                    .foregroundColor(isInputFocused ? AppColors.primary : AppColors.textSecondary)
                                
                                TextField(selectedCourtType.placeholder, text: $inputText)
                                    .font(.system(size: 17))
                                    .focused($isInputFocused)
                                    .autocapitalization(selectedCourtType == .arbitration ? .allCharacters : .none)
                                    .autocorrectionDisabled()
                                    .keyboardType(selectedCourtType == .general ? .URL : .default)
                                    .onChange(of: inputText) { oldValue, newValue in
                                        if selectedCourtType == .arbitration {
                                            // Для АС - автоматическое форматирование в верхний регистр
                                            inputText = newValue.uppercased()
                                        }
                                    }
                                    .onChange(of: selectedCourtType) { oldValue, newValue in
                                        // Очищаем поле при смене типа
                                        inputText = ""
                                        viewModel.errorMessage = nil
                                    }
                                
                                if !inputText.isEmpty {
                                    Button {
                                        inputText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isInputFocused ? AppColors.primary : .clear, lineWidth: 2)
                            )
                            
                            // Подсказка
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13))
                                Text(selectedCourtType.helpText)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 16)
                        
                        // Сообщение об ошибке или успехе
                        if let error = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.warning)
                                
                                Text(error)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 24)
                            .padding(.horizontal, 32)
                        } else if let success = viewModel.successMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.success)
                                
                                Text(success)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Мы начали поиск материалов по делу. Список обновится автоматически.")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, 24)
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Кнопка добавления
                        VStack(spacing: 12) {
                            if viewModel.isAdding {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Добавление дела...")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.bottom, 8)
                            }
                            
                            Button {
                                isInputFocused = false
                                Task {
                                    await viewModel.addCase(
                                        input: inputText,
                                        isSou: selectedCourtType.isSou
                                    )
                                    if viewModel.isAdded {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Добавить в мониторинг")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    canAddCase
                                        ? AppColors.primary
                                        : AppColors.textSecondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: canAddCase ? AppColors.primary.opacity(0.3) : .clear, radius: 10, y: 5)
                            }
                            .disabled(!canAddCase || viewModel.isAdding)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Добавить дело")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }
    
    private var canAddCase: Bool {
        let validation = viewModel.validateInput(inputText, isSou: selectedCourtType.isSou)
        return validation.isValid
    }
}

// MARK: - Court Type Card

struct CourtTypeCard: View {
    let type: AddCaseView.CourtType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                }
                
                VStack(spacing: 2) {
                    Text(type.shortName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textPrimary)
                    
                    Text(type.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppColors.primary : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddCaseView()
}


