//
//  CaseDetailView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Детальная страница дела (iOS 26 Liquid Glass дизайн)
struct CaseDetailView: View {
    let legalCase: LegalCase?
    let caseId: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CaseDetailViewModel()
    @State private var selectedTab: CaseTab = .caseInfo
    @State private var selectedPDFDocument: NormalizedDocument?
    @State private var showPDFViewer = false
    @State private var selectedDocumentDetails: DocumentDetailsContext?
    @State private var showDeleteConfirm = false
    @State private var showActionSheet = false
    @State private var pendingAction: PendingAction?
    @State private var tempText: String = ""
    @State private var showKadOpeningOverlay = false
    
    /// Инициализатор с полным объектом LegalCase
    init(legalCase: LegalCase) {
        self.legalCase = legalCase
        self.caseId = legalCase.id
    }
    
    /// Инициализатор только с ID дела (для навигации из уведомлений)
    init(caseId: Int) {
        self.legalCase = nil
        self.caseId = caseId
    }
    
    /// Название для отображения в заголовке
    private var displayTitle: String {
        if let detail = viewModel.caseDetail {
            return detail.number
        }
        return legalCase?.value ?? "Дело"
    }

    private var isSouCase: Bool {
        if let detail = viewModel.caseDetail {
            return detail.isSou
        }
        return legalCase?.isSou ?? false
    }

    private var externalLinkButtonTitle: String {
        isSouCase ? "Перейти на сайт суда" : "Открыть на kad.arbitr.ru"
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let detail = viewModel.caseDetail {
                contentView(detail: detail)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                loadingView
            }
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        shareCase()
                    } label: {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    
                    if let link = viewModel.caseDetail?.cardLink ?? viewModel.caseDetail?.link ?? legalCase?.cardLink ?? legalCase?.link {
                        Button {
                            openURL(link)
                        } label: {
                            Label(externalLinkButtonTitle, systemImage: "safari")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        confirmAndDelete()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    Button {
                        pendingAction = .rename
                        showActionSheet = true
                    } label: {
                        Label("Переименовать", systemImage: "pencil")
                    }
                    
                    Button {
                        pendingAction = .muteSettings
                        showActionSheet = true
                    } label: {
                        Label("Уведомления", systemImage: "bell.badge")
                    }
                    
                    Button {
                        pendingAction = .addNote
                        showActionSheet = true
                    } label: {
                        Label("Заметка", systemImage: "note.text")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.primary)
                }
            }
        }
        .overlay {
            if showKadOpeningOverlay {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Открываем документ…")
                            .font(.headline)
                        Text("kad.arbitr.ru может показать проверку (капчу).")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 18)
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showKadOpeningOverlay)
        .task {
            await viewModel.loadCaseDetail(caseId: caseId)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
        .fullScreenCover(isPresented: $showPDFViewer) {
            if let document = selectedPDFDocument,
               let pdfURLString = document.pdfURL,
               !pdfURLString.isEmpty {
                // kad.arbitr.ru links are often protected by ddos/captcha and can't be downloaded with URLSession/PDFKit.
                // Show them via SFSafariViewController so the challenge can run and the PDF can open.
                if AppConstants.FeatureFlags.preferKadDirectPdf,
                   pdfURLString.contains("kad.arbitr.ru/Document/Pdf"),
                   let url = URL(string: pdfURLString) {
                    SafariPDFScreen(url: url, title: document.type ?? "Документ")
                } else {
                    // Загружаем PDF и показываем в полноэкранном просмотрщике
                    PDFFullScreenViewer(
                        document: document,
                        caseId: caseId,
                        pdfURLString: pdfURLString
                    )
                }
            }
        }
        .sheet(item: $selectedDocumentDetails) { ctx in
            DocumentDetailSheet(
                context: ctx,
                openCaseLinkTitle: externalLinkButtonTitle,
                onOpenCaseLink: {
                    if let link = viewModel.caseDetail?.cardLink ?? viewModel.caseDetail?.link ?? legalCase?.cardLink ?? legalCase?.link {
                        openURL(link)
                    }
                }
            )
        }
        .confirmationDialog("Удалить дело из мониторинга?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                Task { await deleteCurrentCase() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие удалит дело из вашего мониторинга.")
        }
        .sheet(isPresented: $showActionSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    switch pendingAction {
                    case .rename:
                        TextField("Новое название", text: $tempText)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top)
                    case .addNote:
                        TextEditor(text: $tempText)
                            .frame(minHeight: 160)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                            .padding(.top)
                    case .muteSettings:
                        MuteSettingsView(caseId: caseId)
                    case .none:
                        EmptyView()
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle(sheetTitle)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { showActionSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if pendingAction != .muteSettings {
                            Button("Сохранить") {
                                Task { await performPendingAction() }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Загрузка...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Ошибка", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Повторить") {
                Task {
                    await viewModel.loadCaseDetail(caseId: caseId)
                }
            }
        }
    }
    
    // MARK: - Content View
    
    private func contentView(detail: NormalizedCaseDetail) -> some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Информация о деле
                    caseInfoCard(detail: detail)
                    
                    // Переключатель вкладок
                    tabPicker
                    
                    // Контент вкладки
                    tabContentCards(detail: detail)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Case Info Card
    
    private func caseInfoCard(detail: NormalizedCaseDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            caseInfoView(detail: detail)

            let recent = recentCaseEvents(detail: detail, limit: 6)
            if !recent.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Недавние события")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    ForEach(Array(recent.enumerated()), id: \.element.document.id) { idx, item in
                        RecentEventRow(document: item.document, subtitle: item.instanceName) {
                            openDocument(item.document, subtitle: item.instanceName)
                        }
                        if idx != recent.count - 1 {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .liquidGlassCard(padding: 20, material: .thinMaterial)
    }

    private func recentCaseEvents(detail: NormalizedCaseDetail, limit: Int) -> [(document: NormalizedDocument, instanceName: String)] {
        let flattened: [(NormalizedDocument, String)] = detail.instances.flatMap { inst in
            inst.documents.map { ($0, inst.name) }
        }

        // Сортируем по дате документа (desc). Если даты нет - в конец.
        let sorted = flattened.sorted { a, b in
            let da = a.0.date ?? parseDocumentDate(a.0.displayDate)
            let db = b.0.date ?? parseDocumentDate(b.0.displayDate)
            switch (da, db) {
            case let (lhs?, rhs?):
                if lhs != rhs { return lhs > rhs }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            // Fallback: сохраняем стабильный порядок
            let sa = a.0.displayDate ?? ""
            let sb = b.0.displayDate ?? ""
            if sa != sb { return sa > sb }
            let ta = (a.0.type ?? "") + (a.0.description ?? "")
            let tb = (b.0.type ?? "") + (b.0.description ?? "")
            return ta > tb
        }

        // Дедуп, чтобы одно и то же событие не дублировалось разными источниками.
        var seen = Set<String>()
        var uniq: [(NormalizedDocument, String)] = []
        uniq.reserveCapacity(min(sorted.count, limit))
        for (doc, inst) in sorted {
            let key = "\(doc.displayDate ?? "")|\(doc.type ?? "")|\(doc.description ?? "")|\(doc.documentId ?? "")|\(inst)"
            if seen.insert(key).inserted {
                uniq.append((doc, inst))
                if uniq.count >= limit { break }
            }
        }
        return uniq.map { (document: $0.0, instanceName: $0.1) }
    }

    private func parseDocumentDate(_ s: String?) -> Date? {
        guard let raw = s?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if let d = raw.toDate() { return d }

        // dd.MM.yy / dd.MM.yyyy (+ optional time)
        if let m = raw.wholeMatch(of: /^(?<dd>\d{2})\.(?<mm>\d{2})\.(?<yy>\d{2})(?:\s+(?<hh>\d{2}):(?<min>\d{2}))?$/) {
            guard let dd = Int(m.dd), let mm = Int(m.mm), let yy = Int(m.yy) else { return nil }
            let year = 2000 + yy
            let hh = Int(m.hh ?? "") ?? 12
            let min = Int(m.min ?? "") ?? 0
            return buildDate(year: year, month: mm, day: dd, hour: hh, minute: min)
        }
        if let m = raw.wholeMatch(of: /^(?<dd>\d{2})\.(?<mm>\d{2})\.(?<yyyy>\d{4})(?:\s+(?<hh>\d{2}):(?<min>\d{2}))?$/) {
            guard let dd = Int(m.dd), let mm = Int(m.mm), let yyyy = Int(m.yyyy) else { return nil }
            let hh = Int(m.hh ?? "") ?? 12
            let min = Int(m.min ?? "") ?? 0
            return buildDate(year: yyyy, month: mm, day: dd, hour: hh, minute: min)
        }
        return nil
    }

    private func buildDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.timeZone = .current
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        return comps.date
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        Picker("Раздел", selection: $selectedTab) {
            ForEach(CaseTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .liquidGlassSegmentedStyle()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }
    
    // MARK: - Tab Content Cards
    
    @ViewBuilder
    private func tabContentCards(detail: NormalizedCaseDetail) -> some View {
        VStack(spacing: 12) {
            Group {
                switch selectedTab {
                case .caseInfo:
                    caseInfoCards(detail: detail)
                case .participants:
                    participantsCards(detail: detail)
                case .courts:
                    courtsCards(detail: detail)
                case .acts:
                    actsCards(detail: detail)
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.95))
            ))
        }
        .liquidGlassCard(padding: 20, material: .ultraThinMaterial)
    }
    
    // MARK: - Case Info
    
    private func caseInfoView(detail: NormalizedCaseDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Цепочка номеров дел по инстанциям
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Основной номер дела
                    Text(detail.number)
                        .font(.title2.bold())
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Цепочка инстанций (если есть)
                    if detail.instances.count > 1 {
                        caseNumbersChainView(detail: detail)
                    }
                }
                
                Spacer()
                
                Text(detail.isSou ? "СОЮ" : "АС")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: detail.isSou
                                ? [Color.orange, Color.orange.opacity(0.85)]
                                : [AppColors.primary, AppColors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .shadow(color: (detail.isSou ? Color.orange : AppColors.primary).opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // Метаданные
            HStack(spacing: 16) {
                if let duration = detail.duration, !duration.isEmpty {
                    Label(duration, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let startDate = detail.startDate {
                    Label(formatDate(startDate), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let category = detail.category, !category.isEmpty {
                Text(category)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Case Numbers Chain
    
    /// Отображает цепочку номеров дел по инстанциям (как на kad.arbitr.ru)
    @ViewBuilder
    private func caseNumbersChainView(detail: NormalizedCaseDetail) -> some View {
        let instancesWithNumbers = detail.instances.filter { $0.caseNumber != nil && !$0.caseNumber!.isEmpty }
        
        if !instancesWithNumbers.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(instancesWithNumbers.enumerated()), id: \.element.id) { index, instance in
                    if index > 0 {
                        Image(systemName: "arrow.left")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(instance.caseNumber ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Participants Cards
    
    @ViewBuilder
    private func participantsCards(detail: NormalizedCaseDetail) -> some View {
        if detail.plaintiffs.isEmpty && detail.defendants.isEmpty && detail.third.isEmpty && detail.others.isEmpty {
            ContentUnavailableView("Нет данных", systemImage: "person.2.slash")
        } else {
            if !detail.plaintiffs.isEmpty {
                participantSection(title: "Истцы", participants: detail.plaintiffs, icon: "person.fill", color: .orange)
            }
            
            if !detail.defendants.isEmpty {
                participantSection(title: "Ответчики", participants: detail.defendants, icon: "person.fill", color: .blue)
            }
            
            if !detail.third.isEmpty {
                participantSection(title: "Третьи лица", participants: detail.third, icon: "person.2.fill", color: .gray)
            }
            
            if !detail.others.isEmpty {
                participantSection(title: "Иные лица", participants: detail.others, icon: "person.3.fill", color: .secondary)
            }
        }
    }
    
    private func participantSection(title: String, participants: [ParticipantInfo], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            ForEach(participants) { participant in
                ParticipantRow(participant: participant)
                if participant.id != participants.last?.id {
                    Divider()
                        .background(Material.ultraThinMaterial)
                }
            }
        }
    }
    
    // MARK: - Courts Cards
    
    @ViewBuilder
    private func courtsCards(detail: NormalizedCaseDetail) -> some View {
        if detail.instances.isEmpty {
            ContentUnavailableView("Нет данных", systemImage: "building.columns")
        } else {
            ForEach(detail.instances) { instance in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(instance.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !instance.court.isEmpty {
                        Text(instance.court)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    let judges = Set(instance.documents.flatMap { $0.judges })
                    if !judges.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text(judges.joined(separator: ", "))
                                .font(.caption)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                if instance.id != detail.instances.last?.id {
                    Divider()
                        .background(Material.ultraThinMaterial)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Acts Cards
    
    @ViewBuilder
    private func actsCards(detail: NormalizedCaseDetail) -> some View {
        let acts = detail.instances.flatMap { instance in
            instance.documents.filter { $0.isAct }.map { ($0, instance.name) }
        }
        
        if acts.isEmpty {
            ContentUnavailableView("Нет судебных актов", systemImage: "doc.text")
        } else {
            ForEach(acts, id: \.0.id) { doc, instanceName in
                DocumentRow(document: doc, subtitle: instanceName) {
                    openDocument(doc, subtitle: instanceName)
                }
                if doc.id != acts.last?.0.id {
                    Divider()
                }
            }
        }
    }
    
    // MARK: - Documents Cards
    
    // MARK: - Case Info Cards (Дело)
    
    @ViewBuilder
    private func caseInfoCards(detail: NormalizedCaseDetail) -> some View {
        if detail.instances.isEmpty {
            ContentUnavailableView("Нет документов", systemImage: "folder")
        } else {
            // Документы по инстанциям
            ForEach(detail.instances) { instance in
                if !instance.documents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(instance.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        ForEach(instance.documents.prefix(10)) { doc in
                            DocumentRow(document: doc, subtitle: nil) {
                                openDocument(doc, subtitle: instance.name)
                            }
                        }
                        
                        if instance.documents.count > 10 {
                            Text("+ ещё \(instance.documents.count - 10) документов")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if instance.id != detail.instances.last?.id {
                        Divider()
                            .background(Material.ultraThinMaterial)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            // Ссылка на электронное дело (в самом низу)
            if let link = detail.cardLink ?? detail.link {
                Divider()
                    .background(Material.ultraThinMaterial)
                    .padding(.vertical, 12)
                
                Button {
                    openURL(link)
                } label: {
                    HStack(spacing: 12) {
                        Label(externalLinkButtonTitle, systemImage: "safari")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Tab Content (deprecated - for List style)
    
    @ViewBuilder
    private func tabContent(detail: NormalizedCaseDetail) -> some View {
        switch selectedTab {
        case .participants:
            participantsContent(detail: detail)
        case .courts:
            courtsContent(detail: detail)
        case .acts:
            actsContent(detail: detail)
        case .caseInfo:
            documentsContent(detail: detail)
        }
    }
    
    // MARK: - Participants Tab (List style)
    
    @ViewBuilder
    private func participantsContent(detail: NormalizedCaseDetail) -> some View {
        if !detail.plaintiffs.isEmpty {
            Section("Истцы") {
                ForEach(detail.plaintiffs) { participant in
                    ParticipantRow(participant: participant)
                }
            }
        }
        
        if !detail.defendants.isEmpty {
            Section("Ответчики") {
                ForEach(detail.defendants) { participant in
                    ParticipantRow(participant: participant)
                }
            }
        }
        
        if !detail.third.isEmpty {
            Section("Третьи лица") {
                ForEach(detail.third) { participant in
                    ParticipantRow(participant: participant)
                }
            }
        }
        
        if !detail.others.isEmpty {
            Section("Иные лица") {
                ForEach(detail.others) { participant in
                    ParticipantRow(participant: participant)
                }
            }
        }
        
        if detail.plaintiffs.isEmpty && detail.defendants.isEmpty && detail.third.isEmpty && detail.others.isEmpty {
            Section {
                ContentUnavailableView("Нет данных", systemImage: "person.2.slash")
            }
        }
    }
    
    // MARK: - Courts Tab
    
    @ViewBuilder
    private func courtsContent(detail: NormalizedCaseDetail) -> some View {
        if detail.instances.isEmpty {
            Section {
                ContentUnavailableView("Нет данных", systemImage: "building.columns")
            }
        } else {
            ForEach(detail.instances) { instance in
                Section(instance.name) {
                    if !instance.court.isEmpty {
                        LabeledContent("Суд", value: instance.court)
                    }
                    
                    let judges = Set(instance.documents.flatMap { $0.judges })
                    if !judges.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Судьи")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(Array(judges), id: \.self) { judge in
                                Text(judge)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Acts Tab
    
    @ViewBuilder
    private func actsContent(detail: NormalizedCaseDetail) -> some View {
        let acts = detail.instances.flatMap { instance in
            instance.documents.filter { doc in
                let type = (doc.type ?? "").lowercased()
                return type.contains("определение") ||
                       type.contains("решение") ||
                       type.contains("постановление")
            }.map { ($0, instance.name) }
        }
        
        if acts.isEmpty {
            Section {
                ContentUnavailableView("Нет судебных актов", systemImage: "doc.text")
            }
        } else {
            Section {
                ForEach(acts, id: \.0.id) { doc, instanceName in
                    DocumentRow(document: doc, subtitle: instanceName) {
                        openDocument(doc, subtitle: instanceName)
                    }
                }
            }
        }
    }
    
    // MARK: - Documents Tab
    
    @ViewBuilder
    private func documentsContent(detail: NormalizedCaseDetail) -> some View {
        if detail.instances.isEmpty {
            Section {
                ContentUnavailableView("Нет документов", systemImage: "folder")
            }
        } else {
            // Ссылка на kad.arbitr
            if let link = detail.cardLink ?? detail.link {
                Section {
                    Button {
                        openURL(link)
                    } label: {
                        HStack {
                            Label(externalLinkButtonTitle, systemImage: "safari")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Документы по инстанциям
            ForEach(detail.instances) { instance in
                if !instance.documents.isEmpty {
                    Section(instance.name) {
                        ForEach(instance.documents.prefix(20)) { doc in
                            DocumentRow(document: doc, subtitle: nil) {
                                openDocument(doc, subtitle: instance.name)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }
    
    private func openURL(_ urlString: String) {
        var url = urlString
        if !url.hasPrefix("http") {
            url = "https://\(url)"
        }
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openDocument(_ doc: NormalizedDocument, subtitle: String?) {
        // Если есть полный PDF URL - открываем в приложении
        if let pdfURL = doc.pdfURL, !pdfURL.isEmpty {
            selectedPDFDocument = doc
            if AppConstants.FeatureFlags.preferKadDirectPdf,
               pdfURL.contains("kad.arbitr.ru/Document/Pdf") {
                // Show loader immediately; fullScreenCover/Safari view can mount with a white frame.
                showKadOpeningOverlay = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showPDFViewer = true
                    showKadOpeningOverlay = false
                }
            } else {
                showPDFViewer = true
            }
            return
        }

        // Для событий/обычных записей без PDF показываем подробный просмотр, а не уводим на сайт суда.
        selectedDocumentDetails = DocumentDetailsContext(document: doc, subtitle: subtitle)
    }
    
    private func shareCase() {
        var items: [Any] = []
        
        let caseNumber = viewModel.caseDetail?.number ?? legalCase?.value ?? legalCase?.displayTitle ?? "Дело"
        items.append(caseNumber)
        
        if let link = viewModel.caseDetail?.cardLink ?? legalCase?.cardLink ?? legalCase?.link,
           let url = URL(string: link.hasPrefix("http") ? link : "https://\(link)") {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            // Для iPad
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func confirmAndDelete() {
        showDeleteConfirm = true
    }
    
    private func deleteCurrentCase() async {
        struct DeleteResponse: Codable { let success: Bool?; let status: String?; let message: String? }
        do {
            let endpoint = "/subs/delete?id=\(caseId)&type=case"
            let resp: DeleteResponse = try await APIService.shared.request(endpoint: endpoint, method: .get)
            let status = resp.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let message = resp.message?.lowercased() ?? ""
            let isSuccess = resp.success == true
                || status == "success"
                || message.contains("успех")
                || (message.contains("подписк") && message.contains("удален"))

            if isSuccess {
                NotificationCenter.default.post(name: .monitoringCasesDidChange, object: nil)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dismiss()
                    }
                }
            }
        } catch { print("❌ Delete error: \(error)") }
    }
    
    private enum PendingAction { case rename, muteSettings, addNote }
    
    private var sheetTitle: String {
        switch pendingAction {
        case .rename: return "Переименовать дело"
        case .addNote: return "Заметка"
        case .muteSettings: return "Уведомления"
        case .none: return ""
        }
    }

    private func performPendingAction() async {
        guard let action = pendingAction else { return }
        defer {
            Task { @MainActor in
                showActionSheet = false
                tempText = ""
            }
        }
        switch action {
        case .rename:
            struct SimpleResponse: Codable { let success: Bool?; let status: String?; let message: String? }
            do {
                let response: SimpleResponse = try await APIService.shared.request(
                    endpoint: APIEndpoint.renameCase(id: caseId, name: tempText).path,
                    method: APIEndpoint.renameCase(id: caseId, name: tempText).method,
                    body: APIEndpoint.renameCase(id: caseId, name: tempText).body
                )
                _ = response
            } catch { print("❌ Rename error: \(error)") }
        case .addNote:
            struct SimpleResponse: Codable { let success: Bool?; let status: String?; let message: String? }
            do {
                let response: SimpleResponse = try await APIService.shared.request(
                    endpoint: APIEndpoint.addNote(id: caseId, text: tempText).path,
                    method: APIEndpoint.addNote(id: caseId, text: tempText).method,
                    body: APIEndpoint.addNote(id: caseId, text: tempText).body
                )
                _ = response
            } catch { print("❌ Note error: \(error)") }
        case .muteSettings:
            break
        }
    }
}

// MARK: - Document Details

private struct DocumentDetailsContext: Identifiable {
    let document: NormalizedDocument
    let subtitle: String?
    var id: UUID { document.id }
}

private struct DocumentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let context: DocumentDetailsContext
    let openCaseLinkTitle: String
    let onOpenCaseLink: () -> Void

    private var title: String {
        let t = (context.document.type ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Событие" : t
    }

    private var mainText: String? {
        if let content = context.document.content?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
            return content
        }
        if let desc = context.document.description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
            return desc
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Заголовок
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)

                        if let subtitle = context.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Метаданные
                    VStack(alignment: .leading, spacing: 10) {
                        if let d = context.document.displayDate, !d.isEmpty {
                            metaRow(label: "Дата", value: d)
                        }
                        if let pd = context.document.publishDate, !pd.isEmpty, pd != context.document.displayDate {
                            metaRow(label: "Публикация", value: pd)
                        }
                        if let court = context.document.courtName, !court.isEmpty {
                            metaRow(label: "Суд", value: court)
                        }
                        if !context.document.declarers.isEmpty {
                            metaRow(label: "Податель", value: context.document.declarers.joined(separator: ", "))
                        }
                        if !context.document.judges.isEmpty {
                            metaRow(label: "Судьи", value: context.document.judges.joined(separator: ", "))
                        }
                        if !context.document.contentTypes.isEmpty {
                            metaRow(label: "Типы", value: context.document.contentTypes.joined(separator: " • "))
                        }
                    }
                    .liquidGlassCard(padding: 16, material: .thinMaterial)

                    // Текст
                    if let text = mainText {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .liquidGlassCard(padding: 16, material: .ultraThinMaterial)
                    } else {
                        ContentUnavailableView("Нет текста", systemImage: "text.bubble")
                    }

                    // Действия
                    VStack(spacing: 10) {
                        Button {
                            onOpenCaseLink()
                        } label: {
                            Label(openCaseLinkTitle, systemImage: "safari")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            let toCopy = mainText ?? title
                            UIPasteboard.general.string = toCopy
                        } label: {
                            Label("Копировать текст", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("Подробно")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Tab Enum

enum CaseTab: String, CaseIterable {
    case caseInfo    // Дело - первый по умолчанию
    case participants
    case courts
    case acts
    
    var title: String {
        switch self {
        case .caseInfo: return "Дело"
        case .participants: return "Участники"
        case .courts: return "Суды"
        case .acts: return "Акты"
        }
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: ParticipantInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(participant.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            if let address = participant.address, !address.isEmpty {
                Text(address)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(spacing: 12) {
                if let inn = participant.inn, !inn.isEmpty {
                    Label("ИНН: \(inn)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                if let ogrn = participant.ogrn, !ogrn.isEmpty {
                    Label("ОГРН: \(ogrn)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Document Row

struct DocumentRow: View {
    let document: NormalizedDocument
    let subtitle: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Иконка документа (PDF для судебных актов)
                documentIcon
                
                VStack(alignment: .leading, spacing: 8) {
                    // Тип документа и дата
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        if let type = document.type, !type.isEmpty {
                            Text(type)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer(minLength: 4)
                        
                        if let displayDate = document.displayDate {
                            Text(displayDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Material.ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    
                    // Описание/решение
                    if let description = document.description, !description.isEmpty {
                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // ContentTypes из API (часто это единственный "смысл" записи, например для "Письмо")
                    if !document.contentTypes.isEmpty {
                        Text(document.contentTypes.joined(separator: " • "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Явный Content (если API присылает текст)
                    if let content = document.content, !content.isEmpty {
                        Text(content)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Организация-податель (если есть)
                    if !document.declarers.isEmpty {
                        Label(document.declarers.joined(separator: ", "), systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Судьи (для судебных актов)
                    if !document.judges.isEmpty {
                        Label(document.judges.joined(separator: ", "), systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Дата публикации (если отличается от даты документа)
                    if let publishDate = document.publishDate, !publishDate.isEmpty,
                       publishDate != document.displayDate {
                        Label("Опубликовано: \(publishDate)", systemImage: "calendar")
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Инстанция
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 4)
                
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    /// Иконка документа - PDF для судебных актов, обычная для остальных
    @ViewBuilder
    private var documentIcon: some View {
        if document.isAct {
            // Иконка PDF для судебных актов с градиентом
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 44)
                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 2) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("PDF")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white)
            }
        } else {
            // Обычная иконка документа с материалом
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 36, height: 44)
                
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.secondary, .secondary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

// MARK: - Recent Event Row (compact)

private struct RecentEventRow: View {
    let document: NormalizedDocument
    let subtitle: String?
    let onTap: () -> Void

    private var title: String {
        let t = (document.type ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        let d = (document.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !d.isEmpty { return d }
        return "Событие"
    }

    private var detailText: String? {
        let d = (document.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !d.isEmpty { return d }
        let c = (document.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !c.isEmpty { return c }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: document.isAct ? "doc.fill" : "doc.text")
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if let dd = document.displayDate, !dd.isEmpty {
                            Text(dd)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }

                    if let text = detailText, text != title {
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MuteSettingsView

struct MuteSettingsView: View {
    let caseId: Int
    @State private var muteAll = false
    var body: some View {
        Form {
            Toggle("Отключить все уведомления", isOn: $muteAll)
        }
        .onDisappear {
            Task { await save() }
        }
    }
    private func save() async {
        struct SimpleResponse: Codable { let success: Bool?; let status: String?; let message: String? }
        do {
            let _ : SimpleResponse = try await APIService.shared.request(
                endpoint: APIEndpoint.muteCaseAll(id: caseId, muteAll: muteAll).path,
                method: APIEndpoint.muteCaseAll(id: caseId, muteAll: muteAll).method,
                body: APIEndpoint.muteCaseAll(id: caseId, muteAll: muteAll).body
            )
        } catch { print("❌ Mute settings error: \(error)") }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CaseDetailView(legalCase: LegalCase(
            id: 1,
            title: nil,
            value: "А40-209823/2016",
            name: "Тестовое дело",
            description: nil,
            isSouRaw: false,
            createdAt: "2024-01-01",
            updatedAt: nil,
            status: "monitoring",
            companyId: nil,
            lastEvent: nil,
            totalEvets: nil,
            subscribed: true,
            mutedSide: nil,
            mutedAll: nil,
            new: 0,
            folder: nil,
            favorites: nil,
            cardLink: "https://kad.arbitr.ru/Card/e2815cde-eea0-4a62-b3b0-acf6d88a5dba",
            link: nil,
            sidePl: nil,
            sideDf: nil,
            courtName: nil,
            city: nil
        ))
    }
}
