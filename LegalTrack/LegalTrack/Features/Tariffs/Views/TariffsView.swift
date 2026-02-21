//
//  TariffsView.swift
//  LegalTrack
//

import SwiftUI

struct TariffsView: View {
    @StateObject private var viewModel = TariffsViewModel()
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section {
                if viewModel.isLoading && viewModel.payload == nil {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let error = viewModel.errorMessage, viewModel.payload == nil {
                    errorStateView(error: error)
                } else {
                    headerCard
                }
            }
            .appListCardRow(top: 10, bottom: 10)

            Section("Планы") {
                freePlanCard
                    .appListCardRow(top: 8, bottom: 8)

                if let plans = viewModel.payload?.tarifs, !plans.isEmpty {
                    ForEach(plans) { plan in
                        paidPlanCard(plan)
                            .appListCardRow(top: 8, bottom: 8)
                    }
                } else {
                    ContentUnavailableView("Нет доступных планов", systemImage: "creditcard")
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.restorePurchases()
                        appState.refreshUserProfile()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Восстановить покупки")
                    }
                }
                .disabled(viewModel.isPurchasing)

                if viewModel.payload?.active == true {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.cancelSubscription()
                            appState.refreshUserProfile()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Отменить подписку")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            } footer: {
                Text("Покупки обрабатываются через App Store. После покупки подписка активируется после подтверждения чека сервером.")
            }
        }
        .appListScreenStyle()
        .navigationTitle("Тарифы")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await viewModel.load() }
        .task {
            await viewModel.load()
            appState.refreshUserProfile()
        }
        .overlay(alignment: .bottom) {
            if viewModel.isPurchasing {
                purchasingOverlay
            }
        }
        .alert("Ошибка", isPresented: Binding(get: {
            viewModel.errorMessage != nil && viewModel.payload != nil
        }, set: { _ in
            viewModel.errorMessage = nil
        })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Готово", isPresented: Binding(get: {
            viewModel.infoMessage != nil
        }, set: { _ in
            viewModel.infoMessage = nil
        })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.infoMessage ?? "")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.payload?.active == true ? "Активный тариф" : "Бесплатный тариф")
                    .font(.headline)
                Spacer()
                if viewModel.payload?.active == true {
                    Text("PRO")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppColors.secondary)
                } else {
                    Text("FREE")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.12), in: Capsule())
                        .foregroundStyle(AppColors.primary)
                }
            }

            if let h = viewModel.payload?.header, !h.isEmpty {
                Text(h)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            if let t = viewModel.payload?.text, !t.isEmpty {
                Text(t)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .appCardSurface(cornerRadius: 14)
    }

    private var freePlanCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Бесплатный")
                        .font(.subheadline.weight(.semibold))
                    Text("Доступ к базовым функциям")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("0 р.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
            }

            Text("Мониторинг дел, лента уведомлений, календарь. Платные функции будут отмечены замком.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppColors.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.primary.opacity(0.18), lineWidth: 1)
        )
    }

    private func paidPlanCard(_ plan: TariffPlan) -> some View {
        let title = plan.name ?? "Тариф"
        let price = (plan.price ?? "").isEmpty ? "—" : "\(plan.price ?? "") р."
        let months = plan.month.map { "\($0) мес." }
        let hasUrl = (plan.url ?? "").isEmpty == false
        let productId = viewModel.productId(for: plan)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text([months, productId].compactMap { $0 }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.secondary)
            }

            HStack {
                Spacer()
                if hasUrl, let url = URL(string: plan.url ?? "") {
                    Button {
                        openURL(url)
                    } label: {
                        Text("Оплатить")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else if let productId {
                    Button {
                        Task {
                            await viewModel.buy(productId: productId)
                            appState.refreshUserProfile()
                        }
                    } label: {
                        Text("Купить в App Store")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isPurchasing)
                } else {
                    Text("Недоступно")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(14)
        .appCardSurface(cornerRadius: 14)
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

    private var purchasingOverlay: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Обработка покупки…")
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .padding(.bottom, 10)
    }
}

#Preview {
    NavigationStack {
        TariffsView()
    }
    .environmentObject(AppState())
}
