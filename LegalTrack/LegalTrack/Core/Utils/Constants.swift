//
//  Constants.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Константы приложения
enum AppConstants {
    // MARK: - API
    enum API {
        static let baseURL = "https://arbitr.kazna.tech"
        static let timeout: TimeInterval = 30
    }

    // MARK: - Feature Flags
    enum FeatureFlags {
        /// Temporary: prefer direct kad.arbitr.ru PDF links instead of our proxy (/subs/get-pdf, /api/arb/pdf).
        static let preferKadDirectPdf: Bool = true
    }
    
    // MARK: - OneSignal
    enum OneSignal {
        static let appId = "ea4c198c-ce69-4724-bbc4-22528e581180"
    }
    
    // MARK: - DaData
    enum DaData {
        static let apiKey = "9b909f32f5033c1dcc8c002fcd5d55c9e70276d5"
        static let secretKey = "1e28217456c786f205a5ee98d1663d5ae688a09b"
        static let baseURL = "https://suggestions.dadata.ru/suggestions/api/4_1/rs"
    }
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let authToken = "auth_token"
        static let userProfile = "user_profile"
        static let phoneNumber = "phone_number"
    }
    
    // MARK: - UI
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let tabBarHeight: CGFloat = 83
    }
    
    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }
}
