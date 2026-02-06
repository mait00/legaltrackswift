//
//  MonitoringViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var cases: [LegalCase] = []
    @Published var companies: [Company] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    /// Загрузить дела
    func loadCases() async {
        isLoading = true
        errorMessage = nil
        
        print("📋 Loading cases from: \(APIEndpoint.getSubscriptions.path)")
        
        do {
            let response: SubscriptionsResponse = try await apiService.request(
                endpoint: APIEndpoint.getSubscriptions.path,
                method: .get
            )
            
            print("📋 Subscriptions response received")
            print("📋 Response data exists: \(response.data != nil)")
            print("📋 Response casesArray: \(response.casesArray?.count ?? 0)")
            print("📋 Response data.cases: \(response.data?.cases?.count ?? 0)")
            print("📋 Response data.nestedData.cases: \(response.data?.nestedData?.cases?.count ?? 0)")
            print("📋 Computed cases count: \(response.cases.count)")
            print("📋 Computed companies count: \(response.companies.count)")
            
            if let data = response.data {
                print("📋 Data structure:")
                print("   - cases: \(data.cases?.count ?? 0)")
                print("   - companies: \(data.companies?.count ?? 0)")
                print("   - nestedData exists: \(data.nestedData != nil)")
                if let nested = data.nestedData {
                    print("   - nestedData.cases: \(nested.cases?.count ?? 0)")
                    print("   - nestedData.companies: \(nested.companies?.count ?? 0)")
                }
            }
            
            cases = response.cases
            companies = response.companies

            print("📋 ✅ Final cases count: \(cases.count)")
            print("📋 ✅ Final companies count: \(companies.count)")

            // Логируем данные участников для первых 3 дел
            if !cases.isEmpty {
                print("\n📋 === Participant Data Debug ===")
                for (index, legalCase) in cases.prefix(3).enumerated() {
                    print("📋 Case \(index + 1): \(legalCase.value ?? "No number")")
                    print("   - sidePl (plaintiffs): \(legalCase.sidePl ?? "nil")")
                    if let sideDf = legalCase.sideDf {
                        if let stringValue = sideDf.stringValue {
                            print("   - sideDf (string): \(stringValue)")
                        } else if let arrayValue = sideDf.arrayValue {
                            print("   - sideDf (array): \(arrayValue.count) items")
                            for (i, item) in arrayValue.prefix(2).enumerated() {
                                print("     [\(i)]: \(item.nameSide ?? "No name")")
                            }
                        } else {
                            print("   - sideDf: empty/null")
                        }
                    } else {
                        print("   - sideDf: nil")
                    }
                }
                print("📋 === End Participant Data ===\n")
            }

            if cases.isEmpty {
                print("⚠️ WARNING: Cases array is empty after parsing!")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Error loading cases: \(error)")
            if let apiError = error as? APIError {
                print("❌ API Error details: \(apiError)")
            }
        }
    }
}

