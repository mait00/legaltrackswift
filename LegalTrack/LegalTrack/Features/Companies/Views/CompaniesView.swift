//
//  CompaniesView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран компаний (iOS 26 Liquid Glass дизайн)
struct CompaniesView: View {
    @StateObject private var viewModel = CompaniesViewModel()
    @State private var showAddCompany = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
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
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
            .safeAreaInset(edge: .leading) { Color.clear.frame(width: 0) }
            .safeAreaInset(edge: .trailing) { Color.clear.frame(width: 0) }
            .navigationTitle("Компании")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
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
        HStack(alignment: .center, spacing: 10) {
            // Компактная иконка
            Circle()
                .fill(AppColors.secondary)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "building.2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 3) {
                // Название компании
                Text(company.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // ИНН - компактно
                if let inn = company.inn, !inn.isEmpty {
                    Text("ИНН: \(inn)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                // Бейджи - компактно в одну строку
                HStack(spacing: 6) {
                    // Новые дела
                    if let new = company.new, new > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 9))
                            Text("+\(new)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(6)
                    }

                    // Всего дел
                    if let totalCases = company.totalCases {
                        HStack(spacing: 3) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9))
                            Text(totalCases)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Material.thinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    CompaniesView()
}
