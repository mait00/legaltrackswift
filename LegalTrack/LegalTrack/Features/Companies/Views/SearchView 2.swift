import SwiftUI

/// Экран поиска дел (отдельная вкладка в правом краю таб-бара)
struct CasesSearchView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                VStack(spacing: 12) {
                    // Поле поиска
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ПОИСК ДЕЛА")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Номер дела, название, истец…", text: $searchText)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($isFocused)
                                .onSubmit { }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(Material.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isFocused ? AppColors.primary : .clear, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if searchText.isEmpty {
                        // Пустое состояние
                        ContentUnavailableView(
                            "Поиск дела",
                            systemImage: "magnifyingglass",
                            description: Text("Введите номер, название или участника")
                        )
                        .padding(.top, 40)
                        Spacer()
                    } else {
                        // Результаты поиска
                        List {
                            Section {
                                ForEach(filteredCases) { legalCase in
                                    NavigationLink(destination: CaseDetailView(legalCase: legalCase)) {
                                        CaseRow(legalCase: legalCase)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                Text("\(filteredCases.count) результатов")
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.large)
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
