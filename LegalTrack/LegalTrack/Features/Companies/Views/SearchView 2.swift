import SwiftUI

/// Экран поиска дел (отдельная вкладка в правом краю таб-бара)
struct CasesSearchView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "Поиск дела",
                        systemImage: "magnifyingglass",
                        description: Text("Введите номер, название или участника")
                    )
                } else if filteredCases.isEmpty {
                    ContentUnavailableView(
                        "Ничего не найдено",
                        systemImage: "magnifyingglass",
                        description: Text("Попробуйте другой запрос")
                    )
                } else {
                    Section("\(filteredCases.count) результатов") {
                        ForEach(filteredCases) { legalCase in
                            NavigationLink(destination: CaseDetailView(legalCase: legalCase)) {
                                CaseRow(legalCase: legalCase)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Номер дела, название, истец…")
        }
        .task {
            if viewModel.cases.isEmpty {
                await viewModel.loadCases()
            }
        }
    }
    
    // MARK: - Filtering
    private var filteredCases: [LegalCase] {
        if searchText.isEmpty { return [] }
        var cases = viewModel.cases
        let searchLower = searchText.lowercased()
        
        cases = cases.filter { legalCase in
            if let value = legalCase.value?.lowercased(), value.contains(searchLower) { return true }
            if let name = legalCase.name?.lowercased(), name.contains(searchLower) { return true }
            if let sidePl = legalCase.sidePl?.lowercased(), sidePl.contains(searchLower) { return true }
            if let lastEvent = legalCase.lastEvent?.lowercased(), lastEvent.contains(searchLower) { return true }
            return false
        }
        
        // Сортировка по количеству новых документов, затем по id
        cases.sort { lhs, rhs in
            let lNew = lhs.new ?? 0
            let rNew = rhs.new ?? 0
            if lNew != rNew { return lNew > rNew }
            return lhs.id > rhs.id
        }
        return cases
    }
}

#Preview {
    CasesSearchView()
}
