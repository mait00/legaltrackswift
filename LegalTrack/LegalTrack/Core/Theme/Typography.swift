//
//  Typography.swift
//  LegalTrack
//
//  Created on 2024
//

import SwiftUI

/// Типографика приложения
struct AppTypography {
    // MARK: - Font Sizes
    static let largeTitle: CGFloat = 34
    static let title1: CGFloat = 28
    static let title2: CGFloat = 22
    static let title3: CGFloat = 20
    static let headline: CGFloat = 17
    static let body: CGFloat = 17
    static let callout: CGFloat = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat = 13
    static let caption1: CGFloat = 12
    static let caption2: CGFloat = 11
    
    // MARK: - Font Weights
    enum Weight {
        case regular
        case medium
        case semibold
        case bold
        
        var font: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
}

// MARK: - Text Style Modifiers
extension Text {
    func appStyle(_ size: CGFloat, weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        self
            .font(.system(size: size, weight: weight.font))
            .foregroundColor(color)
    }
    
    func largeTitle(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.largeTitle, weight: weight, color: color)
    }
    
    func title1(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.title1, weight: weight, color: color)
    }
    
    func title2(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.title2, weight: weight, color: color)
    }
    
    func headline(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.headline, weight: weight, color: color)
    }
    
    func body(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.body, weight: weight, color: color)
    }
    
    func caption(weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        appStyle(AppTypography.caption1, weight: weight, color: color)
    }
}

