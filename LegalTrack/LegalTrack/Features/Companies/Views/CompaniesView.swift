//
//  CompaniesView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран компаний
struct CompaniesView: View {
    @StateObject private var viewModel = CompaniesViewModel()
    @State private var path = NavigationPath()
    @State private var showAddCompany = false
    @EnvironmentObject private var appState: AppState
    @State private var showTariffAlert = false
    @State private var showTariffs = false
    @State private var pendingDeleteCompany: Company?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else if viewModel.companies.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Нет компаний",
                            systemImage: "building.2",
                            description: Text("Добавьте первую компанию для мониторинга")
                        )
                    }
                } else {
                    Section {
                        ForEach(viewModel.companies) { company in
                            Button {
                                path.append(company.id)
                            } label: {
                                CompanyRow(company: company)
                            }
                            .buttonStyle(.plain)
                            .appListCardRow()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDeleteCompany = company
                                    showDeleteAlert = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Text("\(viewModel.companies.count) компаний")
                    }
                }
                }
            .appListScreenStyle()
            .navigationTitle("Компании")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadCompanies()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let isTarifActive = appState.isTariffActiveEffective
                        if !isTarifActive {
                            showTariffAlert = true
                        } else {
                            showAddCompany = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddCompany) {
                AddCompanyView()
                    .onDisappear {
                        // Обновляем список компаний после добавления
                        Task {
                            await viewModel.loadCompanies()
                        }
                    }
            }
            .navigationDestination(for: Int.self) { companyId in
                CompanyDetailView(companyId: companyId) {
                    Task {
                        await viewModel.loadCompanies()
                    }
                }
            }
            .navigationDestination(isPresented: $showTariffs) {
                TariffsView()
            }
            .alert("Требуется тариф", isPresented: $showTariffAlert) {
                Button("Тарифы") { showTariffs = true }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Добавление компаний доступно только на платном тарифе.")
            }
            .alert("Удалить компанию?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    guard let company = pendingDeleteCompany else { return }
                    Task {
                        _ = await viewModel.deleteCompany(company)
                        pendingDeleteCompany = nil
                    }
                }
                Button("Отмена", role: .cancel) {
                    pendingDeleteCompany = nil
                }
            } message: {
                Text("Компания будет удалена из мониторинга.")
            }
        }
        .task {
            await viewModel.loadCompanies()
        }
    }
}

/// Строка компании
struct CompanyRow: View {
    let company: Company

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if let inn = company.inn, !inn.isEmpty {
                        Text("ИНН \(inn)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let totalCases = company.totalCases, !totalCases.isEmpty {
                        Text("Дел: \(totalCases)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
            
            Circle()
                .fill(AppColors.secondaryBackground.opacity(0.9))
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 14)
    }

    private var displayName: String {
        let custom = (company.nameCustom ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return company.name
    }
}

#Preview {
    CompaniesView()
        .environmentObject(AppState())
}
