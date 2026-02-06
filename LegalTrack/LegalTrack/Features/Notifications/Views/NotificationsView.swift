//
//  NotificationsView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран уведомлений (iOS 26 Liquid Glass дизайн)
struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedCaseId: Int?
    @State private var selectedCompanyId: Int?
    
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
                } else if let error = viewModel.errorMessage {
                    Section {
                        errorStateView(error: error)
                    }
                } else if viewModel.notifications.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Нет уведомлений",
                            systemImage: "bell.slash",
                            description: Text("Здесь будут появляться уведомления о важных событиях")
                        )
                    }
                } else {
                    // Группируем уведомления по датам
                    ForEach(groupedNotifications, id: \.date) { group in
                        Section {
                            ForEach(group.notifications, id: \.self) { notification in
                                NotificationRow(
                                    notification: notification,
                                    viewModel: viewModel
                                ) {
                                    handleNotificationTap(notification)
                                }
                                .onAppear {
                                    Task {
                                        await viewModel.loadMoreIfNeeded(currentItem: notification)
                                    }
                                }
                            }
                        } header: {
                            Text(group.date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Индикатор загрузки следующей страницы
                    if viewModel.isLoadingMore {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    
                    // Информация о страницах
                    if viewModel.totalPages > 1 {
                        Section {
                            Text("Страница \(viewModel.currentPage) из \(viewModel.totalPages)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
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
            .navigationTitle("Мои подписки")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .refreshable {
                await viewModel.loadNotifications()
            }
            .toolbar {
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Прочитать все") {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                        .font(.subheadline.weight(.medium))
                    }
                }
            }
            .navigationDestination(item: $selectedCaseId) { caseId in
                CaseDetailView(caseId: caseId)
            }
            .navigationDestination(item: $selectedCompanyId) { companyId in
                CompanyDetailView(companyId: companyId)
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
    }
    
    // Группировка уведомлений по датам
    private var groupedNotifications: [(date: String, notifications: [AppNotification])] {
        let grouped = Dictionary(grouping: viewModel.notifications) { $0.meta }
        return grouped.map { (date: $0.key, notifications: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        Task {
            await viewModel.markAsRead(notification)
        }
        
        switch notification.type {
        case .company:
            if let companyId = notification.companyId {
                selectedCompanyId = companyId
            }
        case .caseType:
            selectedCaseId = notification.caseId
        }
    }
    
    // MARK: - Error State View
    
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
                Task {
                    await viewModel.loadNotifications()
                }
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

/// Строка уведомления
struct NotificationRow: View {
    let notification: AppNotification
    let viewModel: NotificationsViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Иконка типа с градиентом
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconBackgroundColor, iconBackgroundColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: iconBackgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: viewModel.iconForType(notification.type))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Заголовок с индикатором
                    HStack(alignment: .top, spacing: 8) {
                        Text(notification.textHeader)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(notification.isRead ? .secondary : .primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        // Индикатор непрочитанного
                        if !notification.isRead {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .shadow(color: Color.red.opacity(0.5), radius: 3, x: 0, y: 1)
                        }
                    }

                    // Основной текст
                    Text(notification.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Подзаголовок (если есть)
                    if !notification.textSubHeader.isEmpty {
                        Text(notification.textSubHeader)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Нижняя строка с меткой типа и документом
                    HStack(spacing: 8) {
                        // Метка типа
                        Text(typeLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(iconBackgroundColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(iconBackgroundColor.opacity(0.15), in: Capsule())

                        // Иконка документа
                        if notification.hasDocument {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.caption2)
                                Text("Документ")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBackgroundColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                iconBackgroundColor.opacity(notification.isRead ? 0.1 : 0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .company:
            return .purple
        case .caseType:
            return .blue
        }
    }

    private var typeLabel: String {
        switch notification.type {
        case .company:
            return "Компания"
        case .caseType:
            return "Дело"
        }
    }
}

#Preview {
    NotificationsView()
}