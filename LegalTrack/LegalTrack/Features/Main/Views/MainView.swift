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
    @State private var selectedFilter: CaseFilter = .all
    @State private var searchText: String = ""
    @Binding var showAddCase: Bool
    
    @State private var pendingDeleteCase: LegalCase?
    @State private var showDeleteAlert = false
    
    init(showAddCase: Binding<Bool> = .constant(false)) {
        _showAddCase = showAddCase
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
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
                        Picker("Тип суда", selection: $selectedFilter) {
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
                } else if filteredCases.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Нет дел",
                            systemImage: "folder",
                            description: Text(selectedFilter == .all ? "Добавьте первое дело" : "Нет дел в этой категории")
                        )
                    }
                } else {
                    Section {
                        ForEach(filteredCases) { legalCase in
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
                            Text("\(filteredCases.count) \(casesWord(filteredCases.count))")
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
            .safeAreaInset(edge: .leading) { Color.clear.frame(width: 0) }
            .safeAreaInset(edge: .trailing) { Color.clear.frame(width: 0) }
            .navigationTitle("Дела")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
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
    
    private var filteredCases: [LegalCase] {
        var cases = viewModel.cases
        
        // Фильтр по типу
        switch selectedFilter {
        case .all:
            break
        case .arbitration:
            cases = cases.filter { $0.isSou != true }
        case .general:
            cases = cases.filter { $0.isSou == true }
        }
        
        // Поиск
        if !searchText.isEmpty {
            cases = cases.filter { legalCase in
                let searchLower = searchText.lowercased()
                if let value = legalCase.value?.lowercased(), value.contains(searchLower) {
                    return true
                }
                if let name = legalCase.name?.lowercased(), name.contains(searchLower) {
                    return true
                }
                if let sidePl = legalCase.sidePl?.lowercased(), sidePl.contains(searchLower) {
                    return true
                }
                return false
            }
        }
        
        // Сортировка: новые/только что добавленные (loading) сверху, затем по количеству новых документов
        cases.sort { lhs, rhs in
            let lhsLoading = lhs.status?.lowercased() == "loading"
            let rhsLoading = rhs.status?.lowercased() == "loading"
            if lhsLoading != rhsLoading { return lhsLoading && !rhsLoading }
            let lNew = lhs.new ?? 0
            let rNew = rhs.new ?? 0
            if lNew != rNew { return lNew > rNew }
            return (lhs.id) > (rhs.id)
        }
        
        return cases
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
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                            .shadow(color: Color.red.opacity(0.2), radius: 3, y: 1)
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
            HStack(spacing: 10) {
                Group {
                    if let courtName = legalCase.courtName, !courtName.isEmpty {
                        Label(courtName, systemImage: "building.columns.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                if let lastEvent = legalCase.lastEvent, !lastEvent.isEmpty {
                    Text("•").font(.caption).foregroundStyle(.tertiary)
                    Label(lastEvent, systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                if let total = totalDocsText {
                    Text("•").font(.caption).foregroundStyle(.tertiary)
                    Label("Документов: \(total)", systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                if let city = legalCase.city, !city.isEmpty {
                    Text("•").font(.caption).foregroundStyle(.tertiary)
                    Label(city, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
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

    @ViewBuilder
    private var participantsView: some View {
        // Отладочная информация
        let _ = print("🔍 [CaseRow] participantsView for case: \(legalCase.value ?? "Unknown")")
        let _ = print("   sidePl: '\(legalCase.sidePl ?? "nil")'")
        let _ = print("   sideDf exists: \(legalCase.sideDf != nil)")
        if let sideDf = legalCase.sideDf {
            let _ = print("   sideDf.stringValue: '\(sideDf.stringValue ?? "nil")'")
            let _ = print("   sideDf.arrayValue count: \(sideDf.arrayValue?.count ?? 0)")
        }
        let _ = print("   isSou: \(isSou)")
        
        // Для СОЮ дел - показываем все стороны без разделения
        if isSou {
            let allSides = parseAllSides()
            let _ = print("   parseAllSides() returned \(allSides.count) sides: \(allSides)")
            
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
            
            let _ = print("   parsePlaintiffs() returned \(plaintiffs.count): \(plaintiffs)")
            let _ = print("   parseDefendants() returned \(defendants.count): \(defendants)")

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
            print("⚠️ [CaseRow] parsePlaintiffs: sidePl is nil or empty for case \(legalCase.value ?? "unknown")")
            return []
        }

        print("🔍 [CaseRow] parsePlaintiffs: sidePl='\(sidePl)' for case \(legalCase.value ?? "unknown")")

        // Разделяем по запятой или точке с запятой
        // Сначала пробуем точку с запятой, потом запятую
        let parts: [String]
        if sidePl.contains(";") {
            parts = sidePl.components(separatedBy: ";")
        } else if sidePl.contains(",") {
            parts = sidePl.components(separatedBy: ",")
        } else {
            // Если нет разделителей, возвращаем всю строку
            let result = [sidePl.trimmingCharacters(in: .whitespaces)]
            print("✅ [CaseRow] parsePlaintiffs: parsed \(result.count) plaintiffs: \(result)")
            return result
        }
        
        let result = parts
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        print("✅ [CaseRow] parsePlaintiffs: parsed \(result.count) plaintiffs: \(result)")
        return result
    }

    private func parseDefendants() -> [String] {
        guard let sideDf = legalCase.sideDf else {
            print("⚠️ [CaseRow] parseDefendants: sideDf is nil for case \(legalCase.value ?? "unknown")")
            return []
        }

        // Если это строка
        if let stringValue = sideDf.stringValue, !stringValue.isEmpty {
            print("🔍 [CaseRow] parseDefendants: sideDf is string='\(stringValue)' for case \(legalCase.value ?? "unknown")")
            
            // Разделяем по запятой или точке с запятой
            let parts: [String]
            if stringValue.contains(";") {
                parts = stringValue.components(separatedBy: ";")
            } else if stringValue.contains(",") {
                parts = stringValue.components(separatedBy: ",")
            } else {
                // Если нет разделителей, возвращаем всю строку
                let result = [stringValue.trimmingCharacters(in: .whitespaces)]
                print("✅ [CaseRow] parseDefendants: parsed \(result.count) defendants: \(result)")
                return result
            }
            
            let result = parts
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            print("✅ [CaseRow] parseDefendants: parsed \(result.count) defendants: \(result)")
            return result
        }

        // Если это массив объектов
        if let arrayValue = sideDf.arrayValue {
            print("🔍 [CaseRow] parseDefendants: sideDf is array with \(arrayValue.count) items for case \(legalCase.value ?? "unknown")")
            let result = arrayValue
                .compactMap { $0.nameSide } // Фильтруем nil значения
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } // Фильтруем пустые строки
            
            print("✅ [CaseRow] parseDefendants: parsed \(result.count) defendants from array: \(result)")
            return result
        }

        print("⚠️ [CaseRow] parseDefendants: sideDf is neither string nor array for case \(legalCase.value ?? "unknown")")
        return []
    }
}

#Preview {
    CasesView()
        .environmentObject(AppState())
}

