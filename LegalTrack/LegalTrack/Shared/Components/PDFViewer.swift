//
//  PDFViewer.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI
import PDFKit

/// Встраиваемый просмотрщик PDF (используя PDFKit)
struct PDFViewer: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Настройка отображения
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Используем белый фон для PDF (стандарт для документов)
        // Это предотвращает черный экран в темной теме
        pdfView.backgroundColor = .white
        
        // Включаем режим страницы для правильного отображения
        pdfView.pageShadowsEnabled = true
        
        // Загружаем PDF
        loadPDF(into: pdfView)
        
        // Отслеживаем изменение страницы
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let page = pdfView.currentPage,
               let pageIndex = pdfView.document?.index(for: page) {
                self.currentPage = pageIndex + 1
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Обновляем документ если URL изменился или документ не загружен
        let currentURL = uiView.document?.documentURL
        if uiView.document == nil || currentURL != url {
            loadPDF(into: uiView)
        } else {
            // Убеждаемся, что масштаб установлен правильно
            if !uiView.autoScales {
                uiView.autoScales = true
            }
        }
    }
    
    private func loadPDF(into pdfView: PDFView) {
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ [PDFViewer] File does not exist at: \(url.path)")
            return
        }
        
        // Загружаем PDF документ
        if let document = PDFDocument(url: url) {
            // Устанавливаем документ
            pdfView.document = document
            
            // Убеждаемся, что фон белый
            pdfView.backgroundColor = .white
            
            // Устанавливаем масштаб и навигацию после загрузки
            DispatchQueue.main.async {
                // Включаем авто-масштабирование
                pdfView.autoScales = true
                
                // Обновляем количество страниц
                self.totalPages = document.pageCount
                
                // Переходим на первую страницу если нужно
                if let firstPage = document.page(at: 0) {
                    pdfView.go(to: firstPage)
                }
                
                // Принудительно обновляем отображение
                pdfView.setNeedsDisplay()
            }
            
            print("✅ [PDFViewer] PDF loaded successfully: \(url.lastPathComponent), pages: \(document.pageCount)")
        } else {
            print("❌ [PDFViewer] Failed to load PDF from: \(url.path)")
            // Пытаемся загрузить данные напрямую
            if let data = try? Data(contentsOf: url) {
                if let document = PDFDocument(data: data) {
                    pdfView.document = document
                    pdfView.backgroundColor = .white
                    DispatchQueue.main.async {
                        pdfView.autoScales = true
                        self.totalPages = document.pageCount
                        if let firstPage = document.page(at: 0) {
                            pdfView.go(to: firstPage)
                        }
                        pdfView.setNeedsDisplay()
                    }
                    print("✅ [PDFViewer] PDF loaded from data: \(url.lastPathComponent)")
                }
            }
        }
    }
}

/// Карточка для быстрого просмотра PDF (встраиваемая в список)
struct PDFPreviewCard: View {
    let document: NormalizedDocument
    let caseId: Int
    
    @State private var pdfURL: URL?
    @State private var isLoading = false
    @State private var isExpanded = false
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var showFullScreen = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок с информацией о документе
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
                if isExpanded && pdfURL == nil {
                    loadPDF()
                }
            } label: {
                HStack(spacing: 14) {
                    // Иконка PDF с градиентом
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 52)
                            .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        VStack(spacing: 3) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("PDF")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(document.type ?? "Судебный акт")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        if let date = document.displayDate {
                            Text(date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Material.ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                        }
                        
                        if let description = document.description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(16)
                .background(Material.thinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Расширяемая секция с PDF
            if isExpanded {
                VStack(spacing: 0) {
                    if isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Загрузка PDF...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                        .frame(height: 300)
                        .background(Material.ultraThinMaterial)
                    } else if let url = pdfURL {
                        // Превью PDF
                        PDFViewer(url: url, currentPage: $currentPage, totalPages: $totalPages)
                            .frame(height: 400)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        // Навигация и кнопки
                        HStack(spacing: 12) {
                            Text("Страница \(currentPage) из \(totalPages)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Material.ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                            
                            Spacer()
                            
                            Button {
                                showFullScreen = true
                            } label: {
                                Label("На весь экран", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Material.thinMaterial,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                            }
                            
                            Button {
                                sharePDF(url: url)
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption.weight(.medium))
                                    .padding(8)
                                    .background(
                                        Material.thinMaterial,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Material.ultraThinMaterial)
                    } else {
                        // Ошибка или нет PDF
                        VStack(spacing: 12) {
                            Image(systemName: errorMessage != nil ? "exclamationmark.triangle.fill" : "doc.text")
                                .font(.title2)
                                .foregroundStyle(errorMessage != nil ? .orange : .secondary)
                            
                            Text(errorMessage ?? "PDF недоступен")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if errorMessage != nil {
                                Button("Повторить") {
                                    errorMessage = nil
                                    loadPDF()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            } else if document.pdfURL == nil {
                                Text("Документ не найден")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Material.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, -8) // Соединяем с заголовком
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let url = pdfURL {
                FullScreenPDFViewer(url: url, documentTitle: document.type ?? "Документ")
            }
        }
    }
    
    private func loadPDF() {
        // Используем pdfURL который формирует полный URL
        guard let urlString = document.pdfURL, !urlString.isEmpty else {
            print("❌ [PDFPreviewCard] No PDF URL available")
            print("   - url: \(document.url ?? "nil")")
            print("   - documentId: \(document.documentId ?? "nil")")
            print("   - caseIdKad: \(document.caseIdKad ?? "nil")")
            errorMessage = "Не удалось сформировать ссылку на документ"
            return
        }
        
        let documentId = document.documentId ?? document.id.uuidString
        
        // Сначала проверяем кэш напрямую
        if let cachedURL = CacheManager.shared.getCachedPDF(caseId: caseId, documentId: documentId) {
            print("📦 [PDFPreviewCard] Using cached PDF: \(cachedURL.lastPathComponent)")
            pdfURL = cachedURL
            isLoading = false
            errorMessage = nil
            return
        }
        
        print("📄 [PDFPreviewCard] Loading PDF from: \(urlString)")
        isLoading = true
        errorMessage = nil
        
        Task {
            // Загружаем и кэшируем
            if let cachedURL = await CacheManager.shared.downloadAndCachePDF(
                from: urlString,
                caseId: caseId,
                documentId: documentId
            ) {
                await MainActor.run {
                    pdfURL = cachedURL
                    isLoading = false
                    errorMessage = nil
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Не удалось загрузить документ. Проверьте подключение к интернету."
                }
            }
        }
    }
    
    private func sharePDF(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// Полноэкранный просмотр PDF
struct FullScreenPDFViewer: View {
    let url: URL
    let documentTitle: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 1
    @State private var totalPages = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Белый фон для PDF
                Color.white
                    .ignoresSafeArea()
                
                PDFViewer(url: url, currentPage: $currentPage, totalPages: $totalPages)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sharePDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Text("Страница \(currentPage) из \(totalPages)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }
    
    private func sharePDF() {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// Полноэкранный просмотр PDF с загрузкой из URL строки
struct PDFFullScreenViewer: View {
    let document: NormalizedDocument
    let caseId: Int
    let pdfURLString: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentPage = 1
    @State private var totalPages = 1
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Загрузка документа...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let url = pdfURL {
                    ZStack {
                        // Белый фон для PDF
                        Color.white
                            .ignoresSafeArea()
                        
                        PDFViewer(url: url, currentPage: $currentPage, totalPages: $totalPages)
                            .ignoresSafeArea(edges: .bottom)
                    }
                } else {
                    ContentUnavailableView {
                        Label("Ошибка загрузки", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage ?? "Не удалось загрузить документ")
                    } actions: {
                        Button("Повторить") {
                            loadPDF()
                        }
                        Button("Закрыть") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(document.type ?? "Документ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                
                if pdfURL != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if let url = pdfURL {
                                sharePDF(url: url)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Text("Страница \(currentPage) из \(totalPages)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            loadPDF()
        }
    }
    
    private func loadPDF() {
        let documentId = document.documentId ?? document.id.uuidString
        
        // Сначала проверяем кэш напрямую
        if let cachedURL = CacheManager.shared.getCachedPDF(caseId: caseId, documentId: documentId) {
            print("📦 [PDFFullScreenViewer] Using cached PDF: \(cachedURL.lastPathComponent)")
            pdfURL = cachedURL
            isLoading = false
            errorMessage = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            if let cachedURL = await CacheManager.shared.downloadAndCachePDF(
                from: pdfURLString,
                caseId: caseId,
                documentId: documentId
            ) {
                await MainActor.run {
                    pdfURL = cachedURL
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Не удалось загрузить документ. Проверьте подключение к интернету."
                }
            }
        }
    }
    
    private func sharePDF(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    PDFPreviewCard(
        document: NormalizedDocument(
            date: Date(),
            displayDate: "23.12.2016",
            publishDate: "24.12.2016",
            type: "Решение",
            description: "Мотивированное решение по делу, рассмотренному в порядке упрощенного производства",
            judges: ["Чекмарев Г. С."],
            declarers: [],
            decision: "Иск удовлетворить полностью",
            url: nil,
            courtName: "АС города Москвы",
            isAct: true,
            contentTypes: ["pdf"],
            documentId: "e2815cde-eea0-4a62-b3b0-acf6d88a5dba",
            caseIdKad: "a40-209823-2016"
        ),
        caseId: 1
    )
    .padding()
}

