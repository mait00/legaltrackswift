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
    
    @State private var pendingDeleteCase: LegalCase?
    @State private var showDeleteAlert = false
    
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
                    
                    // Фильтр по типу суда
                    Section {
                        Picker("Тип суда", selection: $viewModel.selectedFilter) {
                            ForEach(CaseFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .liquidGlassSegmentedStyle()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
                            NavigationLink(destination: CaseDetailView(legalCase: legalCase)) {
                                CaseRow(legalCase: legalCase)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDeleteCase = legalCase
                                    showDeleteAlert = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("\(viewModel.filteredCases.count) \(casesWord(viewModel.filteredCases.count))")
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                }
            .listStyle(.insetGrouped)
            .navigationTitle("Дела")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Поиск по делам")
            .refreshable {
                await viewModel.loadCases()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCase = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
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
        }
        .task {
            await viewModel.loadCases()
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

    private var backgroundColor: Color {
        isSou
            ? Color.orange.opacity(0.08) // Мягкий оранжевый для СОЮ
            : Color.blue.opacity(0.08)   // Мягкий синий для АС
    }

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
        VStack(alignment: .leading, spacing: 12) {
            // Номер дела и бейджи
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(legalCase.value ?? legalCase.name ?? "Дело")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    // Тип суда
                    Text(isSou ? "СОЮ" : "АС")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSou ? Color.orange : Color.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (isSou ? Color.orange : Color.blue).opacity(0.15),
                            in: Capsule()
                        )

                    // Новые документы
                    if newCount > 0 {
                        Text("Новые \(newCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12), in: Capsule())
                    }
                }
            }

            // Состояние загрузки/синхронизации для только что добавленных дел
            // ВАЖНО: для дел со статусом "monitoring" ничего не показываем (статус не выводится в карточку)
            if (legalCase.status?.lowercased() == "loading") || ((legalCase.status == nil) && legalCase.lastEvent == nil && (legalCase.totalEvets == nil || legalCase.totalEvets == "...")) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Идёт поиск и добавление данных по делу…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Участники
            participantsView

            // Метаданные: суд, событие, кол-во документов, город
            VStack(alignment: .leading, spacing: 6) {
                metadataLine(items: firstMetadataLineItems)
                metadataLine(items: secondMetadataLineItems)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            (isSou ? Color.orange : Color.blue).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }

    private var firstMetadataLineItems: [(String, String)] {
        var items: [(String, String)] = []

        if let courtName = legalCase.courtName, !courtName.isEmpty {
            items.append(("building.columns.fill", courtName))
        }

        if let lastEvent = legalCase.lastEvent, !lastEvent.isEmpty {
            items.append(("doc.text", lastEvent))
        }

        return items
    }

    private var secondMetadataLineItems: [(String, String)] {
        var items: [(String, String)] = []

        if let total = totalDocsText {
            items.append(("folder", "Документов: \(total)"))
        }

        if let city = legalCase.city, !city.isEmpty {
            items.append(("mappin.and.ellipse", city))
        }

        return items
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
                        .foregroundStyle(index == 0 ? .secondary : .tertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var participantsView: some View {
        // Для СОЮ дел - показываем все стороны без разделения
        if isSou {
            let allSides = parseAllSides()
            
            if !allSides.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Стороны")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Text(allSides.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } else {
            // Для АС дел - показываем истцов и ответчиков раздельно
            let plaintiffs = parsePlaintiffs()
            let defendants = parseDefendants()

            if !plaintiffs.isEmpty || !defendants.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    // Истцы
                    if !plaintiffs.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.orange)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Истцы")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                Text(plaintiffs.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Ответчики
                    if !defendants.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.blue)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ответчики")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                Text(defendants.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
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
        return Array(Set(allSides))
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
