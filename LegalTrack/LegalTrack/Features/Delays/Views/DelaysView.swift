//
//  DelaysView.swift
//  LegalTrack
//
//  Ported from legacy RN "Delay" screen.
//

import SwiftUI

struct DelaysView: View {
    @StateObject private var viewModel = DelaysViewModel()

    private let refreshTimer = Timer.publish(every: 600, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading && viewModel.shownDelays.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else if let isActive = viewModel.isTarifActive, isActive == false {
                    Section {
                        lockedView
                    }
                } else if let error = viewModel.errorMessage, viewModel.shownDelays.isEmpty {
                    Section {
                        errorStateView(error: error)
                    }
                } else {
                    Section {
                        searchCard
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(Color.clear)
                    }

                    if viewModel.shownDelays.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "Нет задержек",
                                systemImage: "hourglass",
                                description: Text("Попробуйте обновить список или выполнить поиск по номеру дела")
                            )
                        }
                    } else {
                        Section {
                            ForEach(viewModel.shownDelays) { item in
                                DelayCard(item: item)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Задержки")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.load()
            }
        }
        .task {
            await viewModel.load()
        }
        .onReceive(refreshTimer) { _ in
            Task {
                await viewModel.refresh()
            }
        }
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textOnPrimary.opacity(0.9))

                TextField("Введите номер дела", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.default)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
                    .foregroundStyle(AppColors.textOnPrimary)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        Task { await viewModel.search() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textOnPrimary.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Task { await viewModel.search() }
                } label: {
                    Text("Найти")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var lockedView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppColors.warning)

            Text("Функция недоступна")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Данная функция недоступна в бесплатном тарифе. Оплатите тариф и используйте весь функционал приложения.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    private func errorStateView(error: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Ошибка загрузки")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Повторить")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }
}

private struct DelayCard: View {
    let item: DelayItem

    private var startTimeText: String {
        DelayFormatting.timeString(from: item.datetimeStart) ?? "-"
    }

    private var updatedText: String? {
        guard let t = DelayFormatting.updatedTimeString(from: item.delayUpdate) else { return nil }
        return "Обновлено \(t)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundStyle(AppColors.primary)
                    Text(startTimeText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                }

                Spacer(minLength: 8)

                if let updatedText {
                    Text(updatedText)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.grayLight)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.head ?? "")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let s = item.secondLine, !s.isEmpty {
                    Text(s)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let t = item.delayText, !t.isEmpty {
                    Text(t)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .background(AppColors.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    DelaysView()
}

