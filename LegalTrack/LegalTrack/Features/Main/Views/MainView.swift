//
//  MainView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Экран дел (iOS 26 Liquid Glass дизайн)
struct CasesView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @Binding var showAddCase: Bool
    @EnvironmentObject private var appState: AppState
    
    @State private var pendingDeleteCase: LegalCase?
    @State private var showDeleteAlert = false
    @State private var showTariffLimitAlert = false
    @State private var showTariffs = false
    @State private var selectedCase: LegalCase?
    @State private var showSearchBar = false
    
    init(showAddCase: Binding<Bool> = .constant(false)) {
        _showAddCase = showAddCase
    }
    
    var body: some View {
        NavigationStack {
            List {
                    // Баннер офлайн режима
                    if viewModel.isOffline {
                        Section {
                            HStack(spacing: 12) {
                                Image(systemName: "wifi.slash")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Офлайн режим")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    
                                    if let lastSync = viewModel.lastSyncTime {
                                        Text("Данные от \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }

                    // Deep cache prefetch indicator (case details)
                    if viewModel.isPrefetchingCaseDetails, viewModel.prefetchTotalCount > 0 {
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                    Text("Кэширование дел: \(viewModel.prefetchDoneCount)/\(viewModel.prefetchTotalCount)")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }

                                ProgressView(
                                    value: Double(viewModel.prefetchDoneCount),
                                    total: Double(viewModel.prefetchTotalCount)
                                )
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.clear)
                        }
                    }
                    
                    if showSearchBar {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)

                                TextField("Поиск по делам", text: $viewModel.searchText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.subheadline)

                                if !viewModel.searchText.isEmpty {
                                    Button {
                                        viewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                    }
                
                // Список дел
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else if viewModel.filteredCases.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Нет дел",
                            systemImage: "folder",
                            description: Text(viewModel.selectedFilter == .all ? "Добавьте первое дело" : "Нет дел в этой категории")
                        )
                    }
                } else {
                    Section {
                        ForEach(viewModel.filteredCases) { legalCase in
                            Button {
                                selectedCase = legalCase
                            } label: {
                                CaseRow(legalCase: legalCase)
                            }
                            .buttonStyle(.plain)
                            .appListCardRow(horizontal: 12)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDeleteCase = legalCase
                                    showDeleteAlert = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        HStack {
                            Spacer()
                            Text("Всего: \(viewModel.filteredCases.count) \(casesWord(viewModel.filteredCases.count))")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .appListCardRow(top: 8, bottom: 8)
                }
                }
            .appListScreenStyle()
            .navigationTitle("Дела")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadCases()
            }
            .navigationDestination(item: $selectedCase) { legalCase in
                CaseDetailView(legalCase: legalCase)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.selectedFilter = .all
                        } label: {
                            HStack {
                                Text("Все")
                                Spacer()
                                if viewModel.selectedFilter == .all {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Button {
                            viewModel.selectedFilter = .arbitration
                        } label: {
                            HStack {
                                Text("АС")
                                Spacer()
                                if viewModel.selectedFilter == .arbitration {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Button {
                            viewModel.selectedFilter = .general
                        } label: {
                            HStack {
                                Text("СОЮ")
                                Spacer()
                                if viewModel.selectedFilter == .general {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.selectedFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                viewModel.searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        let isTarifActive = appState.isTariffActiveEffective
                        if !isTarifActive, viewModel.cases.count > 5 {
                            showTariffLimitAlert = true
                        } else {
                            showAddCase = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationDestination(isPresented: $showTariffs) {
                TariffsView()
            }
            .alert("Удалить дело?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    if let caseToDelete = pendingDeleteCase {
                        Task {
                            await viewModel.deleteCase(caseToDelete)
                            pendingDeleteCase = nil
                        }
                    }
                }
                Button("Отмена", role: .cancel) {
                    pendingDeleteCase = nil
                }
            } message: {
                Text("Это удалит дело из мониторинга.")
            }
            .alert("Лимит бесплатного тарифа", isPresented: $showTariffLimitAlert) {
                Button("Тарифы") { showTariffs = true }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("В бесплатном тарифе можно отслеживать до 5 дел. Чтобы добавить больше, перейдите на платный тариф.")
            }
        }
        .task {
            await viewModel.loadCases()
        }
        .sheet(isPresented: $showAddCase) {
            AddCaseView(existingCasesCount: viewModel.cases.count)
                .onDisappear {
                    Task { await viewModel.loadCases() }
                }
        }
    }
    
    private func casesWord(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "дел"
        }
        
        switch lastDigit {
        case 1: return "дело"
        case 2, 3, 4: return "дела"
        default: return "дел"
        }
    }
}

/// Фильтр дел
enum CaseFilter: String, CaseIterable {
    case all = "Все"
    case arbitration = "АС" // Арбитражные суды
    case general = "СОЮ"    // Суды общей юрисдикции
}

/// Строка дела в списке (iOS 26 стиль)
struct CaseRow: View {
    let legalCase: LegalCase

    private var isSou: Bool {
        legalCase.isSou == true
    }

    private var accentColor: Color { isSou ? Color.orange : Color.blue }

    private var newCount: Int {
        legalCase.new ?? 0
    }

    private var totalDocsText: String? {
        if let t = legalCase.totalEvets, !t.isEmpty {
            return t
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerLine

            if isLoadingCase {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.85)
                    Text("Добавляем данные по делу…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            participantsCompact

            VStack(alignment: .leading, spacing: 6) {
                metadataLine(items: firstMetadataLineItems)
                metadataLine(items: secondMetadataLineItems)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .appCardSurface(cornerRadius: 16)
        .liquidGlassLeftAccent(color: accentColor.opacity(0.9), width: 4, cornerRadius: 16)
    }

    private var isLoadingCase: Bool {
        (legalCase.status?.lowercased() == "loading") ||
        ((legalCase.status == nil) && legalCase.lastEvent == nil && (legalCase.totalEvets == nil || legalCase.totalEvets == "..."))
    }

    private var primaryTitle: String {
        let number = legalCase.value?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = legalCase.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty { return name }
        if let number, !number.isEmpty { return number }
        return legalCase.displayTitle
    }

    private var lastCourtTitle: String? {
        let court = legalCase.courtName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let court, !court.isEmpty else { return nil }
        return court
    }

    private var subtitleText: String? {
        let number = legalCase.value?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = legalCase.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let court = lastCourtTitle

        var parts: [String] = []
        if let name, !name.isEmpty,
           let number, !number.isEmpty,
           name != number {
            parts.append("№ \(number)")
        }
        if let court {
            parts.append(court)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private var headerLine: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(primaryTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 6)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(isSou ? "СОЮ" : "АС")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.14), in: Capsule())

                        if newCount > 0 {
                            Text("\(newCount)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red, in: Capsule())
                                .accessibilityLabel("Новых документов: \(newCount)")
                        }
                    }

                    if let total = totalDocsText, !total.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(total)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
                    .accessibilityHidden(true)
            }
        }
    }

    private var firstMetadataLineItems: [(String, String)] {
        var items: [(String, String)] = []

        if let lastEvent = legalCase.lastEvent, !lastEvent.isEmpty {
            items.append(("doc.text", lastEvent))
        }

        return items
    }

    private var secondMetadataLineItems: [(String, String)] {
        // City removed; we intentionally keep the second line free for better visual density.
        // If needed later, we can place "last court" here for short court names.
        return []
    }

    @ViewBuilder
    private func metadataLine(items: [(String, String)]) -> some View {
        if !items.isEmpty {
            HStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Circle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 3, height: 3)
                    }

                    Label(item.1, systemImage: item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var participantsCompact: some View {
        // Для СОЮ дел - показываем все стороны без разделения
        if isSou {
            let allSides = parseAllSides()
            
            if !allSides.isEmpty {
                Text("Стороны: \(allSides.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            // Для АС дел - показываем истцов и ответчиков раздельно
            let plaintiffs = parsePlaintiffs()
            let defendants = parseDefendants()

            if !plaintiffs.isEmpty || !defendants.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !plaintiffs.isEmpty {
                        Text("И: \(plaintiffs.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if !defendants.isEmpty {
                        Text("О: \(defendants.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    /// Парсит все стороны для СОЮ дел (без разделения на истцов/ответчиков)
    private func parseAllSides() -> [String] {
        var allSides: [String] = []
        
        // Собираем стороны из sideDf (массив объектов для СОЮ)
        if let sideDf = legalCase.sideDf, let arrayValue = sideDf.arrayValue {
            // Если это массив объектов - берем все nameSide (игнорируем nil)
            allSides = arrayValue
                .compactMap { $0.nameSide } // Фильтруем nil значения
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } // Фильтруем пустые строки
        } else if let sideDf = legalCase.sideDf, let stringValue = sideDf.stringValue, !stringValue.isEmpty {
            // Если это строка - парсим её
            let parts: [String]
            if stringValue.contains(";") {
                parts = stringValue.components(separatedBy: ";")
            } else if stringValue.contains(",") {
                parts = stringValue.components(separatedBy: ",")
            } else {
                parts = [stringValue]
            }
            
            allSides = parts
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        // Также добавляем sidePl, если есть (для СОЮ это может быть дополнительная информация)
        if let sidePl = legalCase.sidePl, !sidePl.isEmpty {
            let parts: [String]
            if sidePl.contains(";") {
                parts = sidePl.components(separatedBy: ";")
            } else if sidePl.contains(",") {
                parts = sidePl.components(separatedBy: ",")
            } else {
                parts = [sidePl]
            }
            
            let plaintiffs = parts
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            allSides.append(contentsOf: plaintiffs)
        }
        
        // Убираем дубликаты
        // Стабильная дедупликация (без рандомного порядка как у Set)
        var seen = Set<String>()
        var ordered: [String] = []
        for s in allSides {
            if seen.insert(s).inserted {
                ordered.append(s)
            }
        }
        return ordered
    }

    private func parsePlaintiffs() -> [String] {
        guard let sidePl = legalCase.sidePl, !sidePl.isEmpty else {
            return []
        }

        // Разделяем по запятой или точке с запятой
        // Сначала пробуем точку с запятой, потом запятую
        let parts: [String]
        if sidePl.contains(";") {
            parts = sidePl.components(separatedBy: ";")
        } else if sidePl.contains(",") {
            parts = sidePl.components(separatedBy: ",")
            } else {
                // Если нет разделителей, возвращаем всю строку
                return [sidePl.trimmingCharacters(in: .whitespaces)]
            }
        
        let result = parts
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return result
    }

    private func parseDefendants() -> [String] {
        guard let sideDf = legalCase.sideDf else {
            return []
        }

        // Если это строка
        if let stringValue = sideDf.stringValue, !stringValue.isEmpty {
            // Разделяем по запятой или точке с запятой
            let parts: [String]
            if stringValue.contains(";") {
                parts = stringValue.components(separatedBy: ";")
            } else if stringValue.contains(",") {
                parts = stringValue.components(separatedBy: ",")
            } else {
                // Если нет разделителей, возвращаем всю строку
                return [stringValue.trimmingCharacters(in: .whitespaces)]
            }
            
            let result = parts
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            return result
        }

        // Если это массив объектов
        if let arrayValue = sideDf.arrayValue {
            return arrayValue
                .compactMap { $0.nameSide } // Фильтруем nil значения
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } // Фильтруем пустые строки
        }

        return []
    }
}

#Preview {
    CasesView()
        .environmentObject(AppState())
}
