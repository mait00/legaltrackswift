//
//  CompanyCaseRow.swift
//  LegalTrack
//
//  Строка дела компании в детальном экране
//

import SwiftUI

struct CompanyCaseRow: View {
    let companyCase: CompanyCase
    let isInMonitoring: Bool
    let monitoringCaseId: Int?
    @Binding var selectedCaseId: Int?
    @State private var isAdding = false
    @State private var showError: String?
    @State private var addedSuccessfully = false
    
    private var isShowingError: Binding<Bool> {
        Binding(get: { showError != nil }, set: { newValue in
            if newValue == false { showError = nil }
        })
    }
    
    private let apiService = APIService.shared
    
    private var isSou: Bool {
        companyCase.type == "Г" || companyCase.type == "У" // Гражданские или уголовные дела - СОЮ
    }
    
    private var accentColor: Color {
        isSou ? Color.orange : Color.blue
    }

    private var effectiveInMonitoring: Bool {
        isInMonitoring || addedSuccessfully
    }

    private var canOpenCase: Bool {
        monitoringCaseId != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if effectiveInMonitoring && canOpenCase {
                    Button {
                        if let monitoringCaseId {
                            selectedCaseId = monitoringCaseId
                        }
                    } label: {
                        Text(companyCase.caseNumber)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(companyCase.caseNumber)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Text(isSou ? "СОЮ" : "АС")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.12), in: Capsule())

                if !effectiveInMonitoring {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Ограниченная информация")
                }

                Spacer(minLength: 0)
            }

            if effectiveInMonitoring {
                if let istec = companyCase.istec, !istec.isEmpty {
                    Text("И: \(istec)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let otvetchik = companyCase.otvetchik, !otvetchik.isEmpty {
                    Text("О: \(otvetchik)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                Label("Ограниченная информация. Добавьте дело в «Мои дела», чтобы открыть карточку.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                if let date = companyCase.date, !date.isEmpty {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                if !effectiveInMonitoring && !isAdding && !addedSuccessfully {
                    Button("Добавить") {
                        Task { await addToMonitoring() }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                } else if isAdding {
                    ProgressView()
                        .scaleEffect(0.85)
                } else if addedSuccessfully {
                    Label("Добавлено", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 6)
        .alert("Ошибка", isPresented: isShowingError) {
            Button("OK") { showError = nil }
        } message: {
            Text(showError ?? "")
        }
    }
    
    private func addToMonitoring() async {
        isAdding = true
        showError = nil
        
        do {
            let response: AddCaseResponse = try await apiService.request(
                endpoint: APIEndpoint.newSubscription(type: "case", value: companyCase.caseNumber, sou: isSou).path,
                method: APIEndpoint.newSubscription(type: "case", value: companyCase.caseNumber, sou: isSou).method,
                body: APIEndpoint.newSubscription(type: "case", value: companyCase.caseNumber, sou: isSou).body
            )
            
            if response.success == true || response.status == "success" {
                addedSuccessfully = true
                NotificationCenter.default.post(name: .monitoringCasesDidChange, object: nil)
            } else {
                showError = response.message ?? "Не удалось добавить дело"
            }
        } catch let apiError as APIError {
            showError = apiError.localizedDescription
            print("❌ Add case API error: \(apiError)")
        } catch {
            showError = "Ошибка при добавлении дела"
            print("❌ Add case unexpected error: \(error)")
        }
        
        isAdding = false
    }
}

#Preview {
    NavigationStack {
        List {
            CompanyCaseRow(
                companyCase: CompanyCase(
                    id: 1,
                    caseNumber: "А40-12345/2024",
                    istec: "ООО Компания",
                    otvetchik: "Иванов И.И.",
                    status: "loading",
                    date: "26-12-2025",
                    type: "Б",
                    meta: "дело синхронизировано"
                ),
                isInMonitoring: false,
                monitoringCaseId: nil,
                selectedCaseId: .constant(nil)
            )
        }
    }
}
