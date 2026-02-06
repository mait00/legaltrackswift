//
//  Colors.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Цветовая палитра приложения с поддержкой тёмной темы
struct AppColors {
    // MARK: - Primary Colors (адаптивные)
    static let primary = Color.adaptive(light: Color(hex: "#1e40af"), dark: Color(hex: "#3b82f6"))
    static let secondary = Color.adaptive(light: Color(hex: "#EB5E1F"), dark: Color(hex: "#f97316"))
    
    // MARK: - Semantic Colors (автоматически адаптируются к теме)
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let surface = Color(uiColor: .systemBackground)
    
    // MARK: - Text Colors (автоматически адаптируются)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let textInactive = Color(uiColor: .quaternaryLabel)
    static let textOnPrimary = Color.white
    
    // MARK: - Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let danger = Color.red
    
    // MARK: - Accent Colors
    static let accent = Color.accentColor
    
    // MARK: - Additional Colors
    static let separator = Color(uiColor: .separator)
    static let border = Color(uiColor: .separator)
    static let fill = Color(uiColor: .systemFill)
    
    // MARK: - Legacy (для совместимости)
    static let tabBarBackground = Color(uiColor: .systemBackground)
    static let grayLight = Color(uiColor: .systemGray6)
    static let muted = Color(uiColor: .secondaryLabel)
    static let textOnDark = Color.white
    static let backgroundDark = Color(hex: "#1e3a5f")
    static let primaryHover = Color(hex: "#1d4ed8")
    static let primaryLight = Color(hex: "#3b82f6")
    static let surfaceGlass = Color(uiColor: .systemBackground).opacity(0.92)
    static let borderGlass = Color(uiColor: .separator).opacity(0.7)
    static let accentHover = Color(hex: "#2563eb")
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Адаптивный цвет для светлой/тёмной темы
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
