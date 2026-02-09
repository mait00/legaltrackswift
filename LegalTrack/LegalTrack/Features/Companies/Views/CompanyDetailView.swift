//
//  CompanyDetailView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Детальная страница компании
struct CompanyDetailView: View {
    let companyId: Int
    @StateObject private var viewModel = CompanyDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitoringViewModel = MonitoringViewModel() // Для проверки наличия дел в мониторинге
    @State private var selectedCaseId: Int?
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.company == nil {
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
        .navigationDestination(item: $selectedCaseId) { caseId in
            CaseDetailView(caseId: caseId)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Загрузка...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
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
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName(company))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let inn = company.inn, !inn.isEmpty {
                        Text("ИНН \(inn)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        if let totalCases = company.totalCases, !totalCases.isEmpty {
                            Label("Дел: \(totalCases)", systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let lastEvent = company.lastEvent, !lastEvent.isEmpty {
                            Label(lastEvent, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let new = company.new, new > 0 {
                        Text("Новых: \(new)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                if viewModel.cases.isEmpty {
                    ContentUnavailableView(
                        "Нет дел",
                        systemImage: "doc.text",
                        description: Text("У этой компании пока нет дел")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(viewModel.cases) { companyCase in
                        CompanyCaseRow(
                            companyCase: companyCase,
                            isInMonitoring: monitoringViewModel.cases.contains { $0.id == companyCase.id },
                            selectedCaseId: $selectedCaseId
                        )
                    }
                }
            } header: {
                Text("Дела компании")
            } footer: {
                Text("Карточка дела открывается только для дел, добавленных в «Мои дела». Для остальных показывается ограниченная информация.")
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
    }

    private func displayName(_ company: Company) -> String {
        let custom = (company.nameCustom ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return company.name
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
