//
//  NotificationsView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран уведомлений (iOS 26 Liquid Glass дизайн)
struct NotificationsView: View {
    private let title: String
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedCaseId: Int?
    @State private var selectedCompanyId: Int?
    
    init(title: String = "Уведомления") {
        self.title = title
    }

    private var isFeed: Bool { title == "Лента" }

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
                } else if let error = viewModel.errorMessage {
                    Section {
                        errorStateView(error: error)
                    }
                } else if viewModel.notifications.isEmpty {
                    Section {
                        ContentUnavailableView(
                            isFeed ? "Нет событий" : "Нет уведомлений",
                            systemImage: isFeed ? "clock" : "bell.slash",
                            description: Text(isFeed ? "Здесь будет появляться лента недавних обновлений" : "Здесь будут появляться уведомления о важных событиях")
                        )
                    }
                } else {
                    // Группируем уведомления по датам
                    ForEach(viewModel.groupedNotifications) { group in
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
                            Text(group.title)
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
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
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
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: viewModel.iconForType(notification.type))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconBackgroundColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(notification.textHeader)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(notification.isRead ? .secondary : .primary)
                            .lineLimit(1)

                        if !notification.isRead {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.textSubHeader.isEmpty ? notification.text : notification.textSubHeader)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !notification.textSubHeader.isEmpty {
                        Text(notification.text)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if notification.hasDocument {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .company:
            return AppColors.secondary
        case .caseType:
            return AppColors.primary
        }
    }

}

#Preview {
    NotificationsView()
}
