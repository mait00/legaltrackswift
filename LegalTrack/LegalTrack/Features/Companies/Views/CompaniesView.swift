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
    @State private var showAddCompany = false
    
    var body: some View {
        NavigationStack {
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
                            NavigationLink(value: company.id) {
                                CompanyRow(company: company)
                            }
                        }
                    } header: {
                        Text("\(viewModel.companies.count) компаний")
                    }
                }
                }
            .listStyle(.insetGrouped)
            .navigationTitle("Компании")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadCompanies()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCompany = true
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
                CompanyDetailView(companyId: companyId)
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if let inn = company.inn, !inn.isEmpty {
                        Text("ИНН \(inn)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let totalCases = company.totalCases, !totalCases.isEmpty {
                        Text("Дел: \(totalCases)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            if let new = company.new, new > 0 {
                Text("+\(new)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red, in: Capsule())
                    .accessibilityLabel("Новых: \(new)")
            }
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        let custom = (company.nameCustom ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return company.name
    }
}

#Preview {
    CompaniesView()
}
