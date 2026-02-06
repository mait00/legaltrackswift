//
//  MainTabView.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Главный TabBar с навигацией (iOS 26 Liquid Glass дизайн)
struct MainTabView: View {
    @State private var selectedTab: Tab = .cases
    @State private var showAddCase = false
    
    enum Tab: Int {
        case cases = 0
        case companies = 1
        case calendar = 2
        case search = 3
        case profile = 4
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: Binding(
                get: { selectedTab.rawValue },
                set: { selectedTab = Tab(rawValue: $0) ?? .cases }
            )) {
                CasesView(showAddCase: $showAddCase)
                    .tabItem {
                        Label("Дела", systemImage: "folder.fill")
                    }
                    .tag(Tab.cases.rawValue)
                
                CompaniesView()
                    .tabItem {
                        Label("Компании", systemImage: "building.2.fill")
                    }
                    .tag(Tab.companies.rawValue)
                
                CalendarView()
                    .tabItem {
                        Label("Календарь", systemImage: "calendar")
                    }
                    .tag(Tab.calendar.rawValue)
                
                CasesSearchView()
                    .tabItem {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }
                    .tag(Tab.search.rawValue)
                
                ProfileView()
                    .tabItem {
                        Label("Профиль", systemImage: "person.fill")
                    }
                    .tag(Tab.profile.rawValue)
            }
            .tint(AppColors.primary)
        }
        .sheet(isPresented: $showAddCase) {
            AddCaseView()
        }
        .onAppear {
            // Настройка TabBar с Liquid Glass эффектом
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenCaseDetail"))) { notification in
            if notification.userInfo?["caseId"] as? Int != nil {
                // Открываем детальную страницу дела
                // TODO: Реализовать навигацию к CaseDetailView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenCompanyDetail"))) { notification in
            if notification.userInfo?["companyId"] as? Int != nil {
                // Открываем детальную страницу компании
                // TODO: Реализовать навигацию к CompanyDetailView
            }
        }
    }
}

struct SearchView: View {
    var body: some View {
        Text("Search Screen")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

