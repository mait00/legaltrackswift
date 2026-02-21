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
    var onDeleted: (() -> Void)? = nil
    @StateObject private var viewModel = CompanyDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitoringViewModel = MonitoringViewModel() // Для проверки наличия дел в мониторинге
    @State private var selectedCaseId: Int?
    @State private var showDeleteAlert = false
    @State private var showDeleteErrorAlert = false
    
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

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .alert("Удалить компанию?", isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive) {
                Task {
                    let deleted = await viewModel.deleteCompany(companyId: companyId)
                    if deleted {
                        onDeleted?()
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                dismiss()
                            }
                        }
                    } else {
                        showDeleteErrorAlert = true
                    }
                }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Компания будет удалена из мониторинга.")
        }
        .alert("Ошибка", isPresented: $showDeleteErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Не удалось удалить компанию")
        }
        .task {
            await viewModel.loadCompanyDetail(companyId: companyId)
            await monitoringViewModel.loadCases() // Загружаем список дел для проверки
        }
        .onReceive(NotificationCenter.default.publisher(for: .monitoringCasesDidChange)) { _ in
            Task { await monitoringViewModel.loadCases() }
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
                        let matchedCase = matchedMonitoringCase(for: companyCase)
                        CompanyCaseRow(
                            companyCase: companyCase,
                            isInMonitoring: matchedCase != nil,
                            monitoringCaseId: matchedCase?.id,
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

    private func matchedMonitoringCase(for companyCase: CompanyCase) -> LegalCase? {
        if let byId = monitoringViewModel.cases.first(where: { $0.id == companyCase.id }) {
            return byId
        }

        let target = normalizeCaseNumber(companyCase.caseNumber)
        guard !target.isEmpty else { return nil }

        return monitoringViewModel.cases.first { legalCase in
            let candidates = [legalCase.value, legalCase.name, legalCase.title]
            return candidates.contains { normalizeCaseNumber($0) == target }
        }
    }

    private func normalizeCaseNumber(_ input: String?) -> String {
        guard let input else { return "" }

        // Убираем пробелы/дефисы-типографику, приводим к uppercase,
        // и унифицируем кириллицу/латиницу для похожих символов в номерах дел.
        let prepared = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .uppercased()

        let map: [Character: Character] = [
            "А": "A", "В": "B", "Е": "E", "К": "K", "М": "M",
            "Н": "H", "О": "O", "Р": "P", "С": "C", "Т": "T",
            "У": "Y", "Х": "X"
        ]

        return String(prepared.map { map[$0] ?? $0 })
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
