//
//  CaseCard.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Контент карточки дела (для использования внутри NavigationLink)
/// Дизайн соответствует веб-версии лигалсистемы.рф
struct CaseCardContent: View {
    let legalCase: LegalCase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Заголовок дела с бейджем
            HStack(alignment: .center, spacing: 8) {
                Text(legalCase.name ?? legalCase.value ?? legalCase.displayTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                // Компактный бейдж
                typeBadge
            }

            // Стороны дела - компактно
            sidesSection

            // Суд - одна строка
            courtSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Material.thinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Type Badge
    
    private var typeBadge: some View {
        Text(legalCase.isSou ? "СОЮ" : "АС")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(legalCase.isSou ? Color.orange : AppColors.primary)
            .cornerRadius(6)
    }
    
    // MARK: - Sides Section
    
    @ViewBuilder
    private var sidesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Истцы - компактно
            if let sidePl = legalCase.sidePl, !sidePl.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.orange)

                    Text(sidePl)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                }
            }

            // Ответчики - компактно
            if let defendants = parseDefendants(), !defendants.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primary)

                    Text(defendants)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                }
            }
        }
    }
    
    // MARK: - Court Section
    
    @ViewBuilder
    private var courtSection: some View {
        if let courtName = legalCase.courtName, !courtName.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 9))
                    .foregroundColor(AppColors.textSecondary)

                Text(courtName)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
    
    
    // MARK: - Helpers
    
    private func parseDefendants() -> String? {
        if let sideDf = legalCase.sideDf {
            if let stringValue = sideDf.stringValue, !stringValue.isEmpty {
                return stringValue
            }
            if let arrayValue = sideDf.arrayValue {
                return arrayValue.compactMap { $0.nameSide }.joined(separator: ", ")
            }
        }
        return nil
    }
    
    private func formatShortDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "ru_RU")
            displayFormatter.dateFormat = "dd.MM.yyyy"
            return displayFormatter.string(from: date)
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "ru_RU")
            displayFormatter.dateFormat = "dd.MM.yyyy"
            return displayFormatter.string(from: date)
        }
        
        return ""
    }
}

/// Карточка дела (с кнопкой)
struct CaseCard: View {
    let legalCase: LegalCase
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            CaseCardContent(legalCase: legalCase)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CaseCardContent(
                legalCase: LegalCase(
                    id: 1,
                    title: nil,
                    value: "А40-60261/2024",
                    name: "Расул Дело",
                    description: nil,
                    isSouRaw: false,
                    createdAt: "2024-01-15T12:00:00.000Z",
                    updatedAt: nil,
                    status: "monitoring",
                    companyId: nil,
                    lastEvent: "Приложения",
                    totalEvets: "3",
                    subscribed: true,
                    mutedSide: nil,
                    mutedAll: nil,
                    new: 0,
                    folder: nil,
                    favorites: false,
                    cardLink: nil,
                    link: nil,
                    sidePl: "ООО ТРАНСКОМЛОГИСТИК",
                    sideDf: nil,
                    courtName: "АС Московского округа",
                    city: "Москва"
                )
            )
            
            CaseCardContent(
                legalCase: LegalCase(
                    id: 2,
                    title: nil,
                    value: "2-1234/2024",
                    name: nil,
                    description: nil,
                    isSouRaw: true,
                    createdAt: "2024-06-20T10:30:00.000Z",
                    updatedAt: nil,
                    status: "monitoring",
                    companyId: nil,
                    lastEvent: nil,
                    totalEvets: nil,
                    subscribed: true,
                    mutedSide: nil,
                    mutedAll: nil,
                    new: nil,
                    folder: nil,
                    favorites: nil,
                    cardLink: nil,
                    link: nil,
                    sidePl: "Иванов И.И.",
                    sideDf: nil,
                    courtName: "Ленинский районный суд г. Ставрополя",
                    city: nil
                )
            )
        }
        .padding()
    }
}
