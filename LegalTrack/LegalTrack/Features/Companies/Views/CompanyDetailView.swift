//
//  CompanyDetailView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Детальная страница компании (iOS 26 Liquid Glass дизайн)
struct CompanyDetailView: View {
    let companyId: Int
    @StateObject private var viewModel = CompanyDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitoringViewModel = MonitoringViewModel() // Для проверки наличия дел в мониторинге
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let company = viewModel.company {
                contentView(company: company)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                loadingView
            }
        }
        .navigationTitle(viewModel.company?.name ?? "Компания")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.company != nil {
                    Menu {
                        Button {
                            shareCompany()
                        } label: {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadCompanyDetail(companyId: companyId)
            await monitoringViewModel.loadCases() // Загружаем список дел для проверки
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ZStack {
            LiquidGlassBackground()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Загрузка...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Ошибка", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Повторить") {
                Task {
                    await viewModel.loadCompanyDetail(companyId: companyId)
                }
            }
        }
    }
    
    // MARK: - Content View
    
    private func contentView(company: Company) -> some View {
        ZStack {
            LiquidGlassBackground()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Карточка компании
                    companyInfoCard(company: company)
                    
                    // Список дел компании
                    casesSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Company Info Card
    
    private func companyInfoCard(company: Company) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Название компании
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let inn = company.inn, !inn.isEmpty {
                        Text("ИНН: \(inn)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if let new = company.new, new > 0 {
                    Text("+\(new)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            
            Divider()
                .background(Material.ultraThinMaterial)
            
            // Информация о компании
            VStack(spacing: 12) {
                // Всего дел
                if let totalCases = company.totalCases, !totalCases.isEmpty {
                    infoRow(icon: "folder.fill", title: "Всего дел", value: totalCases, color: .blue)
                }
                
                // Последнее событие
                if let lastEvent = company.lastEvent, !lastEvent.isEmpty {
                    infoRow(icon: "clock.fill", title: "Последнее событие", value: lastEvent, color: .orange)
                }
                
                // Статус
                if let status = company.status, !status.isEmpty {
                    infoRow(icon: "checkmark.circle.fill", title: "Статус", value: status.capitalized, color: .green)
                }
            }
        }
        .liquidGlassCard(padding: 20, material: .thinMaterial)
    }
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 4)
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Cases Section
    
    private var casesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Дела компании", systemImage: "folder.fill")
                    .font(.headline.weight(.semibold))
                Spacer()
                
                if !viewModel.cases.isEmpty {
                    Text("\(viewModel.cases.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Material.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
            
            if viewModel.cases.isEmpty {
                ContentUnavailableView(
                    "Нет дел",
                    systemImage: "doc.text",
                    description: Text("У этой компании пока нет дел")
                )
                .frame(height: 150)
            } else {
                ForEach(viewModel.cases) { companyCase in
                    CompanyCaseRow(
                        companyCase: companyCase,
                        isInMonitoring: monitoringViewModel.cases.contains { $0.id == companyCase.id }
                    )
                    
                    if companyCase.id != viewModel.cases.last?.id {
                        Divider()
                            .background(Material.ultraThinMaterial)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .liquidGlassCard(padding: 20, material: .ultraThinMaterial)
    }
    
    // MARK: - Share
    
    private func shareCompany() {
        guard let company = viewModel.company else { return }
        
        var items: [Any] = []
        items.append(company.name)
        
        if let inn = company.inn {
            items.append("ИНН: \(inn)")
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(companyId: 1597)
    }
}



