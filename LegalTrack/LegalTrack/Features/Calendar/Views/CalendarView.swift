//
//  CalendarView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI
import UIKit

// MARK: - Calendar Main View

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var dragOffset: CGFloat = 0
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Календарь
                        VStack(spacing: 0) {
                            // Заголовок месяца с навигацией
                            CalendarHeaderView(
                                title: viewModel.monthTitle,
                                onPrevious: viewModel.previousMonth,
                                onNext: viewModel.nextMonth,
                                onToday: viewModel.goToToday
                            )
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            
                            // Дни недели
                            WeekdaysHeaderView()
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.bottom, AppSpacing.xs)
                            
                            // Календарная сетка
                            CalendarGridView(viewModel: viewModel)
                                .padding(.horizontal, AppSpacing.sm)
                                .gesture(
                                    DragGesture(minimumDistance: 50)
                                        .onChanged { value in
                                            dragOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            if value.translation.width < -50 {
                                                viewModel.nextMonth()
                                            } else if value.translation.width > 50 {
                                                viewModel.previousMonth()
                                            }
                                            dragOffset = 0
                                        }
                                )
                        }
                        .appCardSurface(cornerRadius: 20)
                        
                        Divider()
                            .padding(.top, AppSpacing.sm)
                        
                        // Список событий
                        LazyVStack(spacing: AppSpacing.md) {
                            if viewModel.isLoading {
                                loadingView
                            } else if let error = viewModel.errorMessage {
                                errorStateView(error: error)
                            } else if viewModel.eventsForSelectedDate.isEmpty {
                                emptyStateView
                            } else {
                                eventsListView
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, AppSpacing.md)
                }
                .refreshable {
                    await viewModel.loadEvents()
                }
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.goToToday()
                    } label: {
                        Text("Сегодня")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .task {
            await viewModel.loadEvents()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Загрузка событий...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Нет событий")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(selectedDateText)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            
            // Показываем общее количество событий для отладки
            if !viewModel.events.isEmpty {
                Text("Всего событий в календаре: \(viewModel.events.count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
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
                    await viewModel.loadEvents()
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
    
    private var selectedDateText: String {
        CalendarView.selectedDateFormatter.string(from: viewModel.selectedDate)
    }
    
    // MARK: - Events List View
    
    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Заголовок с датой
            Text(selectedDateText)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, AppSpacing.xs)
            
            ForEach(viewModel.eventsForSelectedDate) { event in
                CalendarEventCardView(
                    event: event,
                    displayTitle: viewModel.displayTitle(for: event)
                )
            }
        }
    }
}

private extension CalendarView {
    static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}

// MARK: - Calendar Header View

struct CalendarHeaderView: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
}

// MARK: - Weekdays Header

struct WeekdaysHeaderView: View {
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Calendar Grid View

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        isToday: viewModel.isToday(date),
                        isCurrentMonth: viewModel.isCurrentMonth(date),
                        eventsCount: viewModel.eventsCount(for: date),
                        eventTypes: viewModel.eventTypes(for: date)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let eventsCount: Int
    let eventTypes: [String]
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Номер дня
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(dayColor)
                
                // Индикаторы событий
                if eventsCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(eventTypes.prefix(3), id: \.self) { type in
                            Circle()
                                .fill(eventColor(for: type))
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 5)
                }
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(todayOverlay)
        }
        .buttonStyle(.plain)
    }
    
    private var dayColor: Color {
        if isSelected {
            return .white
        }
        if !isCurrentMonth {
            return Color(uiColor: .quaternaryLabel)
        }
        return .primary
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            AppColors.primary
        } else if isToday {
            AppColors.primary.opacity(0.1)
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder
    private var todayOverlay: some View {
        if isToday && !isSelected {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(AppColors.primary, lineWidth: 1.5)
        }
    }
    
    private func eventColor(for type: String) -> Color {
        switch type.lowercased() {
        case "hearing", "заседание":
            return isSelected ? .white : .blue
        case "deadline", "срок":
            return isSelected ? .white : .red
        case "document", "документ":
            return isSelected ? .white : .green
        case "event", "событие":
            return isSelected ? .white : .orange
        default:
            return isSelected ? .white : AppColors.primary
        }
    }
}

// MARK: - Calendar Event Card View

struct CalendarEventCardView: View {
    let event: CalendarEvent
    let displayTitle: String

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .leading, spacing: 0) {
                // Основной контент
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    // Цветовой индикатор типа события
                    RoundedRectangle(cornerRadius: 2)
                        .fill(event.eventColor)
                        .frame(width: 4)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        // Заголовок и время
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                Text(event.localizedType)
                                    .font(.caption)
                                    .foregroundStyle(event.eventColor)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            if !event.displayTime.isEmpty {
                                Text(event.displayTime)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }

                        // Краткое описание заседания
                        if let summary = normalizedSummary {
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        // Участники дела (third_line)
                        if !participantItems.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondary)
                                    Text("Участники")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Text(participantItems.joined(separator: " • "))
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppColors.secondaryBackground.opacity(0.85))
                            )
                        }

                        // Суд и судья
                        VStack(alignment: .leading, spacing: 4) {
                            if let court = event.court {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.columns")
                                        .font(.caption)
                                    Text(court)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }

                            if let judge = event.judge {
                                HStack(spacing: 4) {
                                    Image(systemName: "person")
                                        .font(.caption)
                                    Text(judge)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Стрелка для перехода
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(AppSpacing.md)
            }
            .padding(0)
            .appCardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private var participantItems: [String] {
        guard let raw = event.thirdLine?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return []
        }

        var parts = raw
            .components(separatedBy: CharacterSet(charactersIn: ";\n|•"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count <= 1, raw.contains(" / ") {
            parts = raw
                .components(separatedBy: " / ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if parts.isEmpty {
            parts = [raw]
        }

        return Array(parts.prefix(3))
    }

    @ViewBuilder
    private var destinationView: some View {
        if let caseId = event.caseId {
            // Если есть caseId, создаём временный LegalCase и показываем детали
            CaseDetailView(legalCase: LegalCase(
                id: caseId,
                title: displayTitle,
                value: event.title,
                name: displayTitle,
                description: nil,
                isSouRaw: event.isSou,
                createdAt: nil,
                updatedAt: nil,
                status: nil,
                companyId: nil,
                lastEvent: nil,
                totalEvets: nil,
                subscribed: nil,
                mutedSide: nil,
                mutedAll: nil,
                new: nil,
                folder: nil,
                favorites: nil,
                cardLink: nil,
                link: nil,
                sidePl: nil,
                sideDf: nil,
                courtName: event.court,
                city: nil
            ))
        } else {
            Text("Детали недоступны")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var normalizedSummary: String? {
        guard let summary = event.description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !summary.isEmpty else {
            return nil
        }

        // If court/judge are rendered in dedicated rows, avoid repeating the same sentence.
        if event.court != nil || event.judge != nil {
            return nil
        }

        return summary
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}
