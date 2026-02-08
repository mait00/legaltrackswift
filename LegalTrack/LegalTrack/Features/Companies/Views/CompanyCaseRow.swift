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
    @Binding var selectedCaseId: Int?
    @State private var isAdding = false
    @State private var showError: String?
    @State private var addedSuccessfully = false
    
    private var isShowingError: Binding<Bool> {
        Binding(get: { showError != nil }, set: { newValue in
            if newValue == false { showError = nil }
        })
    }
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @GestureState private var isPressed = false
    
    private let apiService = APIService.shared
    
    private var isSou: Bool {
        companyCase.type == "Г" || companyCase.type == "У" // Гражданские или уголовные дела - СОЮ
    }
    
    private var accentColor: Color {
        isSou ? Color.orange : Color.blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Номер дела с цветовым акцентом
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    selectedCaseId = companyCase.id
                } label: {
                    Text(companyCase.caseNumber)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 8)
                
                // Компактный бейдж типа суда
                Text(isSou ? "СОЮ" : "АС")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        accentColor.opacity(0.12),
                        in: Capsule()
                    )
            }
            
            // Стороны дела
            VStack(alignment: .leading, spacing: 6) {
                if let istec = companyCase.istec, !istec.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("И:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orange)
                            .frame(width: 20, alignment: .leading)
                        Text(istec)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if let otvetchik = companyCase.otvetchik, !otvetchik.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("О:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.blue)
                            .frame(width: 20, alignment: .leading)
                        Text(otvetchik)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Дата и кнопка добавления
            HStack(spacing: 12) {
                if let date = companyCase.date, !date.isEmpty {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Кнопка добавления на мониторинг (если дела нет в мониторинге)
                if !isInMonitoring && !addedSuccessfully {
                    Button {
                        Task {
                            await addToMonitoring()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isAdding {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                            }
                            Text("Добавить")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [AppColors.secondary, AppColors.secondary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .disabled(isAdding)
                    .buttonStyle(.plain)
                } else if addedSuccessfully {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Добавлено")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            reduceTransparency
                ? AnyShapeStyle(isSou ? Color.orange.opacity(0.08) : Color.blue.opacity(0.08))
                : AnyShapeStyle(Material.ultraThinMaterial),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
                selectedCaseId: .constant(nil)
            )
        }
    }
}
