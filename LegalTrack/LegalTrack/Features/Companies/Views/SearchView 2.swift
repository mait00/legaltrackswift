import SwiftUI
import Foundation

/// Экран сервисов: поиск дел + мониторинг объектов + штрафы
struct CasesSearchView: View {
    @StateObject private var casesViewModel = MonitoringViewModel()
    @StateObject private var objectsViewModel = MonitoringObjectsViewModel()
    @StateObject private var finesViewModel = FinesMonitorViewModel()

    @State private var searchText: String = ""
    @State private var segment: ServicesSegment = .cases

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Раздел", selection: $segment) {
                        ForEach(ServicesSegment.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .liquidGlassSegmentedStyle()
                }
                .appListCardRow(top: 10, bottom: 10)

                switch segment {
                case .cases:
                    casesSection
                case .objects:
                    objectsSection
                case .fines:
                    finesSection
                }
            }
            .appListScreenStyle()
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshCurrentSegment()
            }
        }
        .task {
            if casesViewModel.cases.isEmpty {
                await casesViewModel.loadCases()
            }
        }
        .onChange(of: segment) { _, newValue in
            Task {
                switch newValue {
                case .cases:
                    if casesViewModel.cases.isEmpty {
                        await casesViewModel.loadCases()
                    }
                case .objects:
                    if !objectsViewModel.hasContent {
                        await objectsViewModel.load()
                    }
                case .fines:
                    if !finesViewModel.hasContent {
                        await finesViewModel.load()
                    }
                }
            }
        }
    }

    // MARK: - Cases

    private var casesSection: some View {
        Group {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Номер дела, название, участник", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .appCardSurface(cornerRadius: 12)
            }
            .appListCardRow(top: 6, bottom: 8)

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    ContentUnavailableView(
                        "Поиск дела",
                        systemImage: "magnifyingglass",
                        description: Text("Введите номер, название или участника")
                    )
                }
            } else if filteredCases.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Ничего не найдено",
                        systemImage: "magnifyingglass",
                        description: Text("Попробуйте другой запрос")
                    )
                }
            } else {
                Section("\(filteredCases.count) результатов") {
                    ForEach(filteredCases) { legalCase in
                        NavigationLink(destination: CaseDetailView(legalCase: legalCase)) {
                            CaseRow(legalCase: legalCase)
                        }
                        .appListCardRow(horizontal: 12)
                    }
                }
            }
        }
    }

    // MARK: - Objects

    private var objectsSection: some View {
        ObjectsContentSections(viewModel: objectsViewModel) {
            Task { await objectsViewModel.load(force: true) }
        }
    }

    // MARK: - Fines

    private var finesSection: some View {
        FinesContentSections(viewModel: finesViewModel) {
            Task { await finesViewModel.load(force: true) }
        }
    }

    // MARK: - Helpers

    private var filteredCases: [LegalCase] {
        if searchText.isEmpty { return [] }
        var cases = casesViewModel.cases
        let searchLower = searchText.lowercased()

        cases = cases.filter { legalCase in
            if let value = legalCase.value?.lowercased(), value.contains(searchLower) { return true }
            if let name = legalCase.name?.lowercased(), name.contains(searchLower) { return true }
            if let sidePl = legalCase.sidePl?.lowercased(), sidePl.contains(searchLower) { return true }
            if let lastEvent = legalCase.lastEvent?.lowercased(), lastEvent.contains(searchLower) { return true }
            return false
        }

        cases.sort { lhs, rhs in
            let lNew = lhs.new ?? 0
            let rNew = rhs.new ?? 0
            if lNew != rNew { return lNew > rNew }
            return lhs.id > rhs.id
        }
        return cases
    }

    private func refreshCurrentSegment() async {
        switch segment {
        case .cases:
            await casesViewModel.loadCases()
        case .objects:
            await objectsViewModel.load(force: true)
        case .fines:
            await finesViewModel.load(force: true)
        }
    }
}

/// Отдельная вкладка мониторинга объектов (порт из web)
struct MonitoringObjectsTabView: View {
    @StateObject private var viewModel = MonitoringObjectsViewModel()

    var body: some View {
        NavigationStack {
            List {
                ObjectsContentSections(viewModel: viewModel) {
                    Task { await viewModel.load(force: true) }
                }
            }
            .appListScreenStyle()
            .navigationTitle("Объекты")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.load(force: true)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

/// Отдельная вкладка штрафов (порт из web)
struct FinesTabView: View {
    @StateObject private var viewModel = FinesMonitorViewModel()

    var body: some View {
        NavigationStack {
            List {
                FinesContentSections(viewModel: viewModel) {
                    Task { await viewModel.load(force: true) }
                }
            }
            .appListScreenStyle()
            .navigationTitle("Штрафы")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.load(force: true)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private enum ServicesSegment: String, CaseIterable, Identifiable {
    case cases
    case objects
    case fines

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cases: return "Дела"
        case .objects: return "Объекты"
        case .fines: return "Штрафы"
        }
    }
}

private struct MonitoringObjectItem: Identifiable {
    let id: Int
    let name: String
    let type: String
    let casesCount: Int
    let isActive: Bool
    let lastCheckedText: String?
}

private struct MonitoringObjectSection: Identifiable {
    let id: String
    let title: String
    let totalCases: Int
    let items: [MonitoringObjectItem]
}

private struct MonitoringObjectRow: View {
    let item: MonitoringObjectItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text([item.type, "Дел: \(item.casesCount)", item.lastCheckedText].compactMap { $0 }.joined(separator: " • "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(item.isActive ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 10, height: 10)
                .accessibilityLabel(item.isActive ? "Активен" : "Неактивен")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 14)
    }
}

private struct MonitoringObjectSkeletonRow: View {
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.16))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 180, height: 11)
            }

            Spacer()

            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 10, height: 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 14)
        .redacted(reason: .placeholder)
    }
}

private struct FineMonitorItem: Identifiable {
    let id: String
    let vehicleKey: String
    let vehicle: String
    let amount: Double
    let description: String
    let dateText: String?
    let isPaid: Bool
}

private struct FineVehicleGroup: Identifiable {
    let id: String
    let vehicle: String
    let fines: [FineMonitorItem]
}

private struct FinesSummary {
    let totalCount: Int
    let unpaidCount: Int
    let unpaidAmount: Double
}

private struct FinesSummaryRow: View {
    let summary: FinesSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Неоплачено: \(summary.unpaidCount) из \(summary.totalCount)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Сумма: \(Int(summary.unpaidAmount)) ₽")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "car")
                .font(.title3)
                .foregroundStyle(AppColors.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .appCardSurface(cornerRadius: 14)
    }
}

private struct FineMonitorRow: View {
    let item: FineMonitorItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.isPaid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(item.isPaid ? Color.green : Color.orange)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.vehicle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let date = item.dateText, !date.isEmpty {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            Text("\(Int(item.amount)) ₽")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(item.isPaid ? .secondary : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 14)
    }
}

private struct FineVehicleHeaderRow: View {
    let group: FineVehicleGroup

    private var unpaidCount: Int {
        group.fines.reduce(0) { $0 + ($1.isPaid ? 0 : 1) }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "car.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.vehicle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("Штрафов: \(group.fines.count) • Неоплачено: \(unpaidCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 12)
    }
}

private struct FineMonitorSkeletonSummaryRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.16))
                    .frame(width: 210, height: 14)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 140, height: 11)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .appCardSurface(cornerRadius: 14)
        .redacted(reason: .placeholder)
    }
}

private struct FineMonitorSkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.16))
                    .frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 11)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 120, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 55, height: 11)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 14)
        .redacted(reason: .placeholder)
    }
}

private struct InlineStatusBanner: View {
    let text: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appCardSurface(cornerRadius: 12)
    }
}

private struct BlockingErrorCard: View {
    let text: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Повторить", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

private enum FinesFilter: String, CaseIterable, Identifiable {
    case all
    case unpaid
    case paid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Все"
        case .unpaid: return "Неопл."
        case .paid: return "Опл."
        }
    }
}

private enum ObjectEditorMode {
    case create
    case edit
}

private enum ObjectEditorResult {
    case single(name: String, type: String)
    case group(groupName: String?, names: [String], type: String)
}

private enum ObjectCreateKind: String, CaseIterable, Identifiable {
    case single
    case group

    var id: String { rawValue }

    var title: String {
        switch self {
        case .single: return "Один объект"
        case .group: return "Группа"
        }
    }
}

private struct ObjectEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let mode: ObjectEditorMode
    let initialName: String
    let initialType: String
    let onSubmit: (ObjectEditorResult) async throws -> Void

    @State private var createKind: ObjectCreateKind = .single
    @State private var objectName = ""
    @State private var groupName = ""
    @State private var groupNames = ""
    @State private var objectType = "Прочее"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let objectTypes = ["Транспортное средство", "Недвижимость", "Физическое лицо", "Прочее"]

    var body: some View {
        NavigationStack {
            Form {
                if mode == .create {
                    Section("Что добавить") {
                        Picker("Формат", selection: $createKind) {
                            ForEach(ObjectCreateKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Тип") {
                    Picker("Тип объекта", selection: $objectType) {
                        ForEach(objectTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                if createKind == .group && mode == .create {
                    Section("Объекты группы") {
                        TextField("Название группы (необязательно)", text: $groupName)
                        TextEditor(text: $groupNames)
                            .frame(minHeight: 120)
                        Text("По одному объекту на строку, например: ИНН, ФИО, адрес")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Название") {
                        TextField("Введите название", text: $objectName)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохраняем..." : "Сохранить") {
                        Task { await submit() }
                    }
                    .disabled(isSaving || !isInputValid)
                }
            }
        }
        .onAppear {
            objectName = initialName
            groupName = ""
            groupNames = ""
            createKind = .single
            objectType = objectTypes.contains(initialType) ? initialType : "Прочее"
        }
    }

    private var isInputValid: Bool {
        if createKind == .group && mode == .create {
            let names = groupNames
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return !names.isEmpty
        }
        return !objectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        if isSaving { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if createKind == .group && mode == .create {
                let names = groupNames
                    .split(whereSeparator: \.isNewline)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                let trimmedGroupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                try await onSubmit(.group(groupName: trimmedGroupName.isEmpty ? nil : trimmedGroupName, names: names, type: objectType))
            } else {
                try await onSubmit(.single(name: objectName, type: objectType))
            }
            dismiss()
        } catch {
            errorMessage = mapServicesError(error, hasCachedData: false)
        }
    }
}

private struct FineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: FineMonitorItem

    var body: some View {
        NavigationStack {
            List {
                Section("Статус") {
                    LabeledContent("Состояние") {
                        Text(item.isPaid ? "Оплачен" : "Не оплачен")
                            .foregroundStyle(item.isPaid ? .green : .orange)
                    }
                    LabeledContent("Сумма") {
                        Text("\(Int(item.amount)) ₽")
                    }
                }

                Section("Детали") {
                    LabeledContent("Транспорт") { Text(item.vehicle) }
                    if let date = item.dateText, !date.isEmpty {
                        LabeledContent("Дата") { Text(date) }
                    }
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Штраф")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private struct AddVehicleMonitorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (_ label: String, _ regnum: String, _ regreg: String, _ stsnum: String) async throws -> Void

    @State private var label = ""
    @State private var plateWithRegion = ""
    @State private var stsnum = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Транспорт") {
                    TextField("Название (необязательно)", text: $label)
                    TextField("Госномер + регион (например, А123ВС77)", text: $plateWithRegion)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("СТС", text: $stsnum)
                        .keyboardType(.numberPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Новый транспорт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохраняем..." : "Сохранить") {
                        Task { await submit() }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        parsedPlateWithRegion != nil &&
        !stsnum.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        if isSaving { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        guard let parsedPlateWithRegion else {
            errorMessage = "Укажите госномер с регионом, например А123ВС77"
            return
        }

        do {
            try await onSubmit(
                label.trimmingCharacters(in: .whitespacesAndNewlines),
                parsedPlateWithRegion.regnum,
                parsedPlateWithRegion.regreg,
                stsnum.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
        } catch {
            errorMessage = mapServicesError(error, hasCachedData: false)
        }
    }

    private var parsedPlateWithRegion: (regnum: String, regreg: String)? {
        let cleaned = plateWithRegion
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        var suffixDigits = ""
        for char in cleaned.reversed() {
            if char.isNumber {
                suffixDigits.insert(char, at: suffixDigits.startIndex)
            } else {
                break
            }
        }

        guard (2...3).contains(suffixDigits.count) else { return nil }

        let regnum = String(cleaned.dropLast(suffixDigits.count))
        guard !regnum.isEmpty else { return nil }

        if let regionNumber = Int(suffixDigits), regionNumber > 0 {
            return (regnum: regnum, regreg: String(regionNumber))
        }

        return nil
    }
}

private struct ObjectsContentSections: View {
    @ObservedObject var viewModel: MonitoringObjectsViewModel
    let onRetry: () -> Void
    @State private var activeSheet: ObjectSheet?
    @State private var actionErrorMessage: String?

    private enum ObjectSheet: Identifiable {
        case create
        case edit(MonitoringObjectItem)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let item):
                return "edit-\(item.id)"
            }
        }
    }

    var body: some View {
        Group {
                Section {
                    Button {
                        guard activeSheet == nil else { return }
                        activeSheet = .create
                    } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                        Text("Добавить объект или группу")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .appCardSurface(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
            .appListCardRow(top: 6, bottom: 6)

            if viewModel.isInitialLoading && !viewModel.hasContent {
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        MonitoringObjectSkeletonRow()
                            .appListCardRow()
                    }
                }
            } else if !viewModel.hasContent, let error = viewModel.errorMessage {
                Section {
                    BlockingErrorCard(text: error, onRetry: onRetry)
                }
            } else if viewModel.sections.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Нет объектов",
                        systemImage: "shippingbox",
                        description: Text("Добавьте объекты в веб-версии мониторинга")
                    )
                }
            } else {
                if viewModel.isRefreshing {
                    Section {
                        InlineStatusBanner(text: "Обновляем объекты…", icon: "arrow.triangle.2.circlepath", tint: AppColors.primary)
                    }
                    .appListCardRow(top: 6, bottom: 6)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        InlineStatusBanner(text: message, icon: "exclamationmark.triangle.fill", tint: .orange)
                    }
                    .appListCardRow(top: 0, bottom: 6)
                }

                if let actionErrorMessage {
                    Section {
                        InlineStatusBanner(text: actionErrorMessage, icon: "exclamationmark.triangle.fill", tint: .orange)
                    }
                    .appListCardRow(top: 0, bottom: 6)
                }

                if let updatedText = viewModel.lastUpdatedText {
                    Section {
                        InlineStatusBanner(text: "Обновлено \(updatedText)", icon: "clock", tint: .secondary)
                    }
                    .appListCardRow(top: 0, bottom: 4)
                }

                ForEach(viewModel.sections) { section in
                    Section("\(section.title) · Дел: \(section.totalCases)") {
                        ForEach(section.items) { item in
                            MonitoringObjectRow(item: item)
                                .appListCardRow()
                                .contextMenu {
                                    Button {
                                        Task {
                                            do {
                                                actionErrorMessage = nil
                                                try await viewModel.setObjectActive(item: item, isActive: !item.isActive)
                                            } catch {
                                                actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                            }
                                        }
                                    } label: {
                                        Label(item.isActive ? "Отключить" : "Включить", systemImage: item.isActive ? "pause.circle" : "play.circle")
                                    }

                                    Button {
                                        guard activeSheet == nil else { return }
                                        activeSheet = .edit(item)
                                    } label: {
                                        Label("Изменить", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        Task {
                                            do {
                                                actionErrorMessage = nil
                                                try await viewModel.deleteObject(id: item.id)
                                            } catch {
                                                actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                            }
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            do {
                                                actionErrorMessage = nil
                                                try await viewModel.deleteObject(id: item.id)
                                            } catch {
                                                actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                            }
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                    Button {
                                        guard activeSheet == nil else { return }
                                        activeSheet = .edit(item)
                                    } label: {
                                        Label("Изменить", systemImage: "pencil")
                                    }
                                    .tint(AppColors.primary)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        Task {
                                            do {
                                                actionErrorMessage = nil
                                                try await viewModel.setObjectActive(item: item, isActive: !item.isActive)
                                            } catch {
                                                actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                            }
                                        }
                                    } label: {
                                        Label(item.isActive ? "Отключить" : "Включить", systemImage: item.isActive ? "pause.circle" : "play.circle")
                                    }
                                    .tint(item.isActive ? .orange : .green)
                                }
                        }
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                ObjectEditorSheet(
                    title: "Новый объект",
                    mode: .create,
                    initialName: "",
                    initialType: "Прочее"
                ) { result in
                    do {
                        actionErrorMessage = nil
                        switch result {
                        case .single(let name, let type):
                            try await viewModel.createObject(name: name, type: type)
                        case .group(let groupName, let names, let type):
                            try await viewModel.createGroup(groupName: groupName, names: names, type: type)
                        }
                    } catch {
                        actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                    }
                }
            case .edit(let item):
                ObjectEditorSheet(
                    title: "Изменить объект",
                    mode: .edit,
                    initialName: item.name,
                    initialType: item.type
                ) { result in
                    do {
                        actionErrorMessage = nil
                        if case .single(let name, let type) = result {
                            try await viewModel.updateObject(item: item, newName: name, newType: type)
                        }
                    } catch {
                        actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                    }
                }
            }
        }
    }
}

private struct FinesContentSections: View {
    @ObservedObject var viewModel: FinesMonitorViewModel
    let onRetry: () -> Void
    @State private var filter: FinesFilter = .all
    @State private var activeSheet: FinesSheet?
    @State private var actionErrorMessage: String?

    private enum FinesSheet: Identifiable {
        case details(FineMonitorItem)
        case addVehicle

        var id: String {
            switch self {
            case .details(let fine):
                return "fine-\(fine.id)"
            case .addVehicle:
                return "add-vehicle"
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.isInitialLoading && !viewModel.hasContent {
                Section {
                    FineMonitorSkeletonSummaryRow()
                        .appListCardRow(top: 8, bottom: 8)
                }
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        FineMonitorSkeletonRow()
                            .appListCardRow()
                    }
                }
            } else if !viewModel.hasContent, let error = viewModel.errorMessage {
                Section {
                    BlockingErrorCard(text: error, onRetry: onRetry)
                }
            } else if viewModel.items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Нет штрафов",
                        systemImage: "car",
                        description: Text("Штрафы не найдены или пока не подключены")
                    )
                }
            } else {
                Section {
                    Button {
                        guard activeSheet == nil else { return }
                        activeSheet = .addVehicle
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("Добавить транспорт в мониторинг штрафов")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .appCardSurface(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
                .appListCardRow(top: 6, bottom: 6)

                Section {
                    Picker("Фильтр", selection: $filter) {
                        ForEach(FinesFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .liquidGlassSegmentedStyle()
                }
                .appListCardRow(top: 6, bottom: 6)

                if viewModel.isRefreshing {
                    Section {
                        InlineStatusBanner(text: "Обновляем штрафы…", icon: "arrow.triangle.2.circlepath", tint: AppColors.primary)
                    }
                    .appListCardRow(top: 6, bottom: 6)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        InlineStatusBanner(text: message, icon: "exclamationmark.triangle.fill", tint: .orange)
                    }
                    .appListCardRow(top: 0, bottom: 6)
                }

                if let actionErrorMessage {
                    Section {
                        InlineStatusBanner(text: actionErrorMessage, icon: "exclamationmark.triangle.fill", tint: .orange)
                    }
                    .appListCardRow(top: 0, bottom: 6)
                }

                if let updatedText = viewModel.lastUpdatedText {
                    Section {
                        InlineStatusBanner(text: "Обновлено \(updatedText)", icon: "clock", tint: .secondary)
                    }
                    .appListCardRow(top: 0, bottom: 4)
                }

                Section {
                    FinesSummaryRow(summary: viewModel.summary)
                        .appListCardRow(top: 8, bottom: 8)
                }

                Section("\(filteredItems.count) записей • \(filteredGroups.count) ТС") {
                    ForEach(filteredGroups) { group in
                        FineVehicleHeaderRow(group: group)
                            .appListCardRow(top: 10, bottom: 4)

                        ForEach(group.fines) { fine in
                            Button {
                                guard activeSheet == nil else { return }
                                activeSheet = .details(fine)
                            } label: {
                                FineMonitorRow(item: fine)
                            }
                            .buttonStyle(.plain)
                            .appListCardRow()
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            actionErrorMessage = nil
                                            try await viewModel.deleteFine(fine)
                                        } catch {
                                            actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                        }
                                    }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }

                                Button {
                                    Task {
                                        do {
                                            actionErrorMessage = nil
                                            try await viewModel.setFinePaid(fine, isPaid: !fine.isPaid)
                                        } catch {
                                            actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                                        }
                                    }
                                } label: {
                                    Label(fine.isPaid ? "Не оплачено" : "Оплачено", systemImage: fine.isPaid ? "xmark.circle" : "checkmark.circle")
                                }
                                .tint(fine.isPaid ? .orange : .green)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .details(let fine):
                FineDetailSheet(item: fine)
            case .addVehicle:
                AddVehicleMonitorSheet { label, regnum, regreg, stsnum in
                    do {
                        actionErrorMessage = nil
                        try await viewModel.createVehicleMonitor(
                            label: label,
                            regnum: regnum,
                            regreg: regreg,
                            stsnum: stsnum
                        )
                    } catch {
                        actionErrorMessage = mapServicesError(error, hasCachedData: viewModel.hasContent)
                    }
                }
            }
        }
    }

    private var filteredItems: [FineMonitorItem] {
        switch filter {
        case .all:
            return viewModel.items
        case .unpaid:
            return viewModel.items.filter { !$0.isPaid }
        case .paid:
            return viewModel.items.filter { $0.isPaid }
        }
    }

    private var filteredGroups: [FineVehicleGroup] {
        let grouped = Dictionary(grouping: filteredItems, by: \.vehicleKey)
        return grouped
            .map { key, fines in
                let sorted = fines.sorted {
                    if $0.isPaid != $1.isPaid { return !$0.isPaid && $1.isPaid }
                    return ($0.dateText ?? "") > ($1.dateText ?? "")
                }
                return FineVehicleGroup(
                    id: key,
                    vehicle: sorted.first?.vehicle ?? "Транспорт",
                    fines: sorted
                )
            }
            .sorted {
                let lhsUnpaid = $0.fines.contains { !$0.isPaid }
                let rhsUnpaid = $1.fines.contains { !$0.isPaid }
                if lhsUnpaid != rhsUnpaid { return lhsUnpaid && !rhsUnpaid }
                return $0.vehicle < $1.vehicle
            }
    }
}

@MainActor
private final class MonitoringObjectsViewModel: ObservableObject {
    @Published var sections: [MonitoringObjectSection] = []
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastUpdatedAt: Date?

    var hasContent: Bool { !sections.isEmpty }
    var lastUpdatedText: String? {
        guard let lastUpdatedAt else { return nil }
        return lastUpdatedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private let cacheManager = CacheManager.shared
    private let swrTTL: TimeInterval = 24 * 60 * 60
    private let objectTypes = ["Транспортное средство", "Недвижимость", "Физическое лицо", "Прочее"]

    func load(force: Bool = false) async {
        if isInitialLoading || isRefreshing { return }
        errorMessage = nil

        if let cached = await cacheManager.loadMonitoringObjectsPayloadAsync() {
            let cachedParsed = parseSections(from: cached.data)
            if !cachedParsed.sections.isEmpty {
                sections = cachedParsed.sections
                lastUpdatedAt = cached.fetchedAt
                print("📦 [Objects] using cache, age: \(Int(Date().timeIntervalSince(cached.fetchedAt)))s, payload: \(cachedParsed.payloadKind)")
            }
        }

        let hasCachedContent = hasContent
        let isFresh = lastUpdatedAt.map { cacheManager.isPayloadFresh($0, ttl: swrTTL) } ?? false
        let shouldRefresh = force || !hasCachedContent || !isFresh
        if !shouldRefresh { return }

        if hasCachedContent {
            isRefreshing = true
        } else {
            isInitialLoading = true
        }
        defer {
            isInitialLoading = false
            isRefreshing = false
        }

        do {
            let response = try await fetchLegalTrackV1(
                path: "/monitoring-objects/",
                query: [
                    URLQueryItem(name: "skip", value: "0"),
                    URLQueryItem(name: "limit", value: "200"),
                    URLQueryItem(name: "sort_by", value: "created_at"),
                    URLQueryItem(name: "sort_order", value: "desc")
                ]
            )

            let parsed = parseSections(from: response.data)
            sections = parsed.sections
            lastUpdatedAt = Date()
            errorMessage = nil
            await cacheManager.saveMonitoringObjectsPayloadAsync(response.data, fetchedAt: lastUpdatedAt ?? Date())
            print("🌐 [Objects] source=network payload=\(parsed.payloadKind) sections=\(parsed.sections.count)")
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            errorMessage = mapServicesError(error, hasCachedData: hasCachedContent)
            print("❌ [Objects] refresh failed: \(error.localizedDescription)")
        }
    }

    func createObject(name: String, type: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw APIError.serverError(message: "Название объекта обязательно")
        }
        let safeType = objectTypes.contains(type) ? type : "Прочее"

        _ = try await fetchLegalTrackV1Request(
            path: "/monitoring-objects/",
            method: .post,
            jsonBody: [
                "name": trimmed,
                "object_type": safeType
            ]
        )
        await load(force: true)
    }

    func createGroup(groupName: String?, names: [String], type: String) async throws {
        let normalized = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !normalized.isEmpty else {
            throw APIError.serverError(message: "Добавьте хотя бы один объект")
        }
        let safeType = objectTypes.contains(type) ? type : "Прочее"

        let objects = normalized.map { ["name": $0] }
        var payload: [String: Any] = [
            "object_type": safeType,
            "objects": objects
        ]
        if let groupName, !groupName.isEmpty {
            payload["group_name"] = groupName
        }
        _ = try await fetchLegalTrackV1Request(
            path: "/monitoring-objects/group",
            method: .post,
            jsonBody: payload
        )
        await load(force: true)
    }

    func updateObject(item: MonitoringObjectItem, newName: String, newType: String) async throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw APIError.serverError(message: "Название объекта обязательно")
        }
        let safeType = objectTypes.contains(newType) ? newType : item.type

        _ = try await fetchLegalTrackV1Request(
            path: "/monitoring-objects/\(item.id)",
            method: .put,
            jsonBody: [
                "name": trimmed,
                "object_type": safeType
            ]
        )
        await load(force: true)
    }

    func setObjectActive(item: MonitoringObjectItem, isActive: Bool) async throws {
        _ = try await fetchLegalTrackV1Request(
            path: "/monitoring-objects/\(item.id)",
            method: .put,
            jsonBody: [
                "name": item.name,
                "object_type": item.type,
                "is_active": isActive
            ]
        )
        await load(force: true)
    }

    func deleteObject(id: Int) async throws {
        _ = try await fetchLegalTrackV1Request(path: "/monitoring-objects/\(id)", method: .delete)
        await load(force: true)
    }

    private struct ParsedObjectsResult {
        let sections: [MonitoringObjectSection]
        let payloadKind: String
    }

    private func parseSections(from data: Data) -> ParsedObjectsResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return ParsedObjectsResult(sections: [], payloadKind: "invalid")
        }

        let array = extractArray(from: json, keys: ["data", "results", "items", "objects", "groups"])
        var seenIds = Set<Int>()
        var groupedSections: [MonitoringObjectSection] = []
        var flatItems: [MonitoringObjectItem] = []

        for any in array {
            guard let dict = any as? [String: Any] else { continue }

            if let nestedObjects = dict["objects"] as? [Any] {
                let groupId = stringValue(dict["group_id"]) ?? stringValue(dict["id"]) ?? UUID().uuidString
                let groupName = stringValue(dict["group_name"]) ??
                    stringValue(dict["name"]) ??
                    stringValue(dict["object_type"]) ??
                    "Группа"
                var groupItems: [MonitoringObjectItem] = []

                for nested in nestedObjects {
                    guard let objectDict = nested as? [String: Any],
                          let parsed = parseObjectItem(from: objectDict) else { continue }
                    if seenIds.insert(parsed.id).inserted {
                        groupItems.append(parsed)
                    }
                }

                let sorted = groupItems.sorted {
                    if $0.casesCount != $1.casesCount { return $0.casesCount > $1.casesCount }
                    return $0.name < $1.name
                }

                let totalCases = intValue(dict["total_cases"]) > 0
                    ? intValue(dict["total_cases"])
                    : sorted.reduce(0) { $0 + $1.casesCount }

                if !sorted.isEmpty {
                    groupedSections.append(
                        MonitoringObjectSection(
                            id: "group_\(groupId)",
                            title: groupName,
                            totalCases: totalCases,
                            items: sorted
                        )
                    )
                }
                continue
            }

            if let parsed = parseObjectItem(from: dict),
               seenIds.insert(parsed.id).inserted {
                flatItems.append(parsed)
            }
        }

        if !groupedSections.isEmpty {
            let sortedSections = groupedSections.sorted {
                if $0.totalCases != $1.totalCases { return $0.totalCases > $1.totalCases }
                return $0.title < $1.title
            }
            return ParsedObjectsResult(sections: sortedSections, payloadKind: "grouped")
        }

        let groupedByType = Dictionary(grouping: flatItems, by: { $0.type })
        let sections = groupedByType.keys.sorted().map { type in
            let items = (groupedByType[type] ?? []).sorted {
                if $0.casesCount != $1.casesCount { return $0.casesCount > $1.casesCount }
                return $0.name < $1.name
            }
            return MonitoringObjectSection(
                id: "type_\(type)",
                title: type,
                totalCases: items.reduce(0) { $0 + $1.casesCount },
                items: items
            )
        }

        return ParsedObjectsResult(sections: sections, payloadKind: "flat")
    }

    private func parseObjectItem(from dict: [String: Any]) -> MonitoringObjectItem? {
        let id = intValue(dict["id"])
        guard id > 0 else { return nil }

        let name = stringValue(dict["name"]) ?? stringValue(dict["title"]) ?? "Объект #\(id)"
        let type = stringValue(dict["object_type"]) ?? stringValue(dict["type"]) ?? "Объект"
        let cases = intValue(dict["cases_count"] ?? dict["total_cases"] ?? dict["casesCount"])
        let isActive = boolValue(dict["is_active"] ?? dict["active"]) ?? true
        let lastChecked = stringValue(dict["last_checked_at"] ?? dict["updated_at"])

        return MonitoringObjectItem(
            id: id,
            name: name,
            type: type,
            casesCount: max(0, cases),
            isActive: isActive,
            lastCheckedText: shortDate(lastChecked)
        )
    }
}

@MainActor
private final class FinesMonitorViewModel: ObservableObject {
    @Published var items: [FineMonitorItem] = []
    @Published var summary = FinesSummary(totalCount: 0, unpaidCount: 0, unpaidAmount: 0)
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastUpdatedAt: Date?

    var hasContent: Bool { !items.isEmpty }
    var lastUpdatedText: String? {
        guard let lastUpdatedAt else { return nil }
        return lastUpdatedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private let cacheManager = CacheManager.shared
    private let swrTTL: TimeInterval = 24 * 60 * 60

    func load(force: Bool = false) async {
        if isInitialLoading || isRefreshing { return }
        errorMessage = nil

        if let cached = await cacheManager.loadFinesPayloadAsync() {
            let parsed = parseItems(from: cached.data)
            if !parsed.isEmpty {
                apply(parsed)
                lastUpdatedAt = cached.fetchedAt
                print("📦 [Fines] using cache, age: \(Int(Date().timeIntervalSince(cached.fetchedAt)))s")
            }
        }

        let hasCachedContent = hasContent
        let isFresh = lastUpdatedAt.map { cacheManager.isPayloadFresh($0, ttl: swrTTL) } ?? false
        let shouldRefresh = force || !hasCachedContent || !isFresh
        if !shouldRefresh { return }

        if hasCachedContent {
            isRefreshing = true
        } else {
            isInitialLoading = true
        }
        defer {
            isInitialLoading = false
            isRefreshing = false
        }

        do {
            let response = try await fetchLegalTrackV1(path: "/fines/", query: [URLQueryItem(name: "limit", value: "200")])
            let parsed = parseItems(from: response.data)
            apply(parsed)
            lastUpdatedAt = Date()
            errorMessage = nil
            await cacheManager.saveFinesPayloadAsync(response.data, fetchedAt: lastUpdatedAt ?? Date())
            print("🌐 [Fines] source=network items=\(parsed.count)")
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            errorMessage = mapServicesError(error, hasCachedData: hasCachedContent)
            print("❌ [Fines] refresh failed: \(error.localizedDescription)")
        }
    }

    func setFinePaid(_ fine: FineMonitorItem, isPaid: Bool) async throws {
        _ = try await fetchLegalTrackV1Request(
            path: "/fines/\(fine.id)",
            method: .put,
            jsonBody: ["is_paid": isPaid]
        )
        await load(force: true)
    }

    func deleteFine(_ fine: FineMonitorItem) async throws {
        _ = try await fetchLegalTrackV1Request(path: "/fines/\(fine.id)", method: .delete)
        await load(force: true)
    }

    func createVehicleMonitor(label: String, regnum: String, regreg: String, stsnum: String) async throws {
        let cleanedRegnum = regnum
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedRegnum.isEmpty else {
            throw APIError.serverError(message: "Укажите госномер")
        }
        guard let region = Int(regreg.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw APIError.serverError(message: "Укажите корректный регион")
        }
        guard let sts = Int(stsnum.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw APIError.serverError(message: "Укажите корректный номер СТС")
        }

        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayLabel = trimmedLabel.isEmpty ? "\(cleanedRegnum) \(region)" : trimmedLabel

        _ = try await fetchLegalTrackV1Request(
            path: "/vehicles/",
            method: .post,
            jsonBody: [
                "regnum": cleanedRegnum,
                "regreg": region,
                "stsnum": sts,
                "label": displayLabel
            ]
        )
        await load(force: true)
    }

    private func apply(_ parsed: [FineMonitorItem]) {
        let sorted = parsed.sorted {
            if $0.isPaid != $1.isPaid { return !$0.isPaid && $1.isPaid }
            return ($0.dateText ?? "") > ($1.dateText ?? "")
        }

        items = sorted

        let unpaid = sorted.filter { !$0.isPaid }
        summary = FinesSummary(
            totalCount: sorted.count,
            unpaidCount: unpaid.count,
            unpaidAmount: unpaid.reduce(0) { $0 + $1.amount }
        )
    }

    private func parseItems(from data: Data) -> [FineMonitorItem] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        let array = extractArray(from: json, keys: ["data", "results", "items", "fines"])

        return array.compactMap { any in
            guard let dict = any as? [String: Any] else { return nil }

            let id = stringValue(dict["id"]) ?? stringValue(dict["num_post"]) ?? UUID().uuidString
            let amount = doubleValue(dict["summa"] ?? dict["amount"] ?? dict["fine_amount"])
            let isPaid = boolValue(dict["is_paid"] ?? dict["paid"]) ?? {
                if let status = stringValue(dict["status"])?.lowercased() {
                    return status == "paid" || status == "оплачен"
                }
                return false
            }()

            let vehicleDict = dict["vehicle"] as? [String: Any]
            let regnumRaw = stringValue(dict["regnum"])
                ?? stringValue(dict["vehicle_regnum"])
                ?? stringValue(vehicleDict?["regnum"])
            let regionRaw = stringValue(dict["regreg"])
                ?? stringValue(dict["region"])
                ?? stringValue(dict["vehicle_regreg"])
                ?? stringValue(vehicleDict?["regreg"])
                ?? stringValue(vehicleDict?["region"])
            let fallbackVehicle = stringValue(dict["vehicle_label"])
                ?? stringValue(dict["vehicle"])
                ?? stringValue(vehicleDict?["label"])

            let vehicleIdentity = normalizedVehicleIdentity(
                regnum: regnumRaw,
                region: regionRaw,
                fallbackLabel: fallbackVehicle
            )

            let description = stringValue(dict["koap_text"]) ??
                stringValue(dict["description"]) ??
                stringValue(dict["num_post"]) ??
                "Штраф"

            let date = stringValue(dict["date_post"] ?? dict["date_decis"] ?? dict["date"] ?? dict["created_at"])

            return FineMonitorItem(
                id: id,
                vehicleKey: vehicleIdentity.key,
                vehicle: vehicleIdentity.display,
                amount: max(0, amount),
                description: description,
                dateText: shortDate(date),
                isPaid: isPaid
            )
        }
    }
}

private func extractArray(from json: Any, keys: [String]) -> [Any] {
    if let arr = json as? [Any] {
        return arr
    }
    if let dict = json as? [String: Any] {
        for key in keys {
            if let arr = dict[key] as? [Any] {
                return arr
            }
        }
        if let data = dict["data"] as? [String: Any] {
            for key in keys {
                if let arr = data[key] as? [Any] {
                    return arr
                }
            }
        }
    }
    return []
}

private func stringValue(_ value: Any?) -> String? {
    if let str = value as? String {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    if let num = value as? NSNumber {
        return num.stringValue
    }
    return nil
}

private func normalizedVehicleIdentity(
    regnum: String?,
    region: String?,
    fallbackLabel: String?
) -> (key: String, display: String) {
    let normalizedRegnum = normalizedPlate(regnum)
    let normalizedRegion = normalizedRegion(region)

    if let normalizedRegnum {
        let display = [normalizedRegnum, normalizedRegion].compactMap { $0 }.joined(separator: " ")
        let key = "plate:\(normalizedRegnum)|\(normalizedRegion ?? "")"
        return (key: key, display: display)
    }

    if let fallback = fallbackLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty {
        let compactDisplay = fallback.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let key = "label:\(compactDisplay.uppercased())"
        return (key: key, display: compactDisplay)
    }

    return (key: "unknown", display: "Транспорт")
}

private func normalizedPlate(_ value: String?) -> String? {
    guard let value else { return nil }
    let cleaned = value
        .uppercased()
        .replacingOccurrences(of: " ", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? nil : cleaned
}

private func normalizedRegion(_ value: String?) -> String? {
    guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return nil
    }
    let digits = raw.filter(\.isNumber)
    if let numeric = Int(digits), numeric > 0 {
        return String(numeric)
    }
    return digits.isEmpty ? nil : digits
}

private func intValue(_ value: Any?) -> Int {
    if let i = value as? Int { return i }
    if let n = value as? NSNumber { return n.intValue }
    if let s = value as? String, let i = Int(s) { return i }
    return 0
}

private func doubleValue(_ value: Any?) -> Double {
    if let d = value as? Double { return d }
    if let f = value as? Float { return Double(f) }
    if let n = value as? NSNumber { return n.doubleValue }
    if let s = value as? String {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }
    return 0
}

private func boolValue(_ value: Any?) -> Bool? {
    if let b = value as? Bool { return b }
    if let n = value as? NSNumber { return n.intValue != 0 }
    if let s = value as? String {
        switch s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y": return true
        case "0", "false", "no", "n": return false
        default: return nil
        }
    }
    return nil
}

private func shortDate(_ value: String?) -> String? {
    guard let value,
          let date = value.toDate() else {
        return value?.isEmpty == false ? value : nil
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}

private struct LegalTrackResponse {
    let data: Data
    let statusCode: Int
}

private func mapServicesError(_ error: Error, hasCachedData: Bool) -> String {
    if let apiError = error as? APIError {
        switch apiError {
        case .httpError(let statusCode) where statusCode == 404:
            return "Сервис временно недоступен"
        case .networkError:
            return hasCachedData
                ? "Проблема соединения, показаны сохраненные данные"
                : (apiError.errorDescription ?? "Проблема соединения")
        case .serverError(let message):
            if message.contains("404") {
                return "Сервис временно недоступен"
            }
            return hasCachedData ? "Показаны сохраненные данные: \(message)" : message
        default:
            return apiError.errorDescription ?? "Ошибка загрузки"
        }
    }
    return hasCachedData ? "Проблема соединения, показаны сохраненные данные" : "Не удалось загрузить данные"
}

private func fetchLegalTrackV1(path: String, query: [URLQueryItem] = []) async throws -> LegalTrackResponse {
    try await fetchLegalTrackV1Request(path: path, method: .get, query: query, jsonBody: nil)
}

private func fetchLegalTrackV1Request(
    path: String,
    method: HTTPMethod,
    query: [URLQueryItem] = [],
    jsonBody: [String: Any]? = nil
) async throws -> LegalTrackResponse {
    var components = URLComponents(string: "https://api.legaltrack.ru/api/v1\(path)")
    if !query.isEmpty {
        components?.queryItems = query
    }
    guard let url = components?.url else {
        throw APIError.invalidURL
    }

    guard let token = KeychainManager.shared.get(forKey: AppConstants.StorageKeys.authToken), !token.isEmpty else {
        throw APIError.serverError(message: "Не авторизован")
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.timeoutInterval = min(AppConstants.API.timeout, 20)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(token, forHTTPHeaderField: "Authorization")
    if let jsonBody {
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
    }

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw APIError.serverError(message: "Сервис временно недоступен")
            }
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorResponse.message ?? "Ошибка сервера")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return LegalTrackResponse(data: data, statusCode: httpResponse.statusCode)
    } catch is CancellationError {
        throw CancellationError()
    } catch let error as APIError {
        throw error
    } catch let urlError as URLError {
        if urlError.code == .cancelled {
            throw CancellationError()
        }
        throw APIError.networkError(urlError.localizedDescription)
    } catch {
        throw APIError.networkError(error.localizedDescription)
    }
}

#Preview {
    CasesSearchView()
}
