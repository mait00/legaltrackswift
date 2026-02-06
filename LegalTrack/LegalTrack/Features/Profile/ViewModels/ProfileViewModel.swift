//
//  ProfileViewModel.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// ViewModel для страницы профиля
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Редактируемые поля
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var userType: UserType = .lawyer
    
    private let apiService = APIService.shared
    
    enum UserType: String, CaseIterable, Identifiable {
        case lawyer = "1"
        case company = "2"
        case individual = "3"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .lawyer: return "Юрист"
            case .company: return "Компания"
            case .individual: return "Физ. лицо"
            }
        }
        
        var icon: String {
            switch self {
            case .lawyer: return "briefcase.fill"
            case .company: return "building.2.fill"
            case .individual: return "person.fill"
            }
        }
    }
    
    /// Загрузить профиль пользователя
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: UserProfileResponse = try await apiService.request(
                endpoint: APIEndpoint.getProfile.path,
                method: .get
            )
            
            print("👤 [Profile] Response received")
            
            if let userData = response.data {
                self.user = userData
                self.firstName = userData.firstName ?? ""
                self.lastName = userData.lastName ?? ""
                self.email = userData.email ?? ""
                self.phone = userData.phone ?? ""
                if let type = userData.type {
                    self.userType = UserType(rawValue: type) ?? .lawyer
                }
                
                print("✅ [Profile] Loaded profile: \(fullName), type: \(userType.displayName), email: \(email)")
                isLoading = false
                errorMessage = nil
            } else {
                print("⚠️ [Profile] No data in response")
                isLoading = false
                errorMessage = "Не удалось загрузить данные профиля"
            }
        } catch {
            isLoading = false
            print("❌ [Profile] Load profile error: \(error)")
            
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось загрузить профиль"
            } else {
                errorMessage = "Не удалось загрузить профиль: \(error.localizedDescription)"
            }
        }
    }
    
    /// Сохранить профиль
    func saveProfile() async -> Bool {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let request = EditProfilePayload(
                firstName: firstName,
                lastName: lastName,
                email: email,
                type: userType.rawValue
            )
            
            let _: SimpleResponse = try await apiService.request(
                endpoint: APIEndpoint.editProfile(firstName: firstName, lastName: lastName, email: email, type: userType.rawValue).path,
                method: .post,
                body: request
            )
            
            isSaving = false
            successMessage = "Профиль сохранён"
            
            // Обновляем локальные данные
            user?.firstName = firstName
            user?.lastName = lastName
            user?.email = email
            user?.type = userType.rawValue
            
            return true
        } catch {
            isSaving = false
            errorMessage = "Не удалось сохранить профиль"
            print("❌ Save profile error: \(error)")
            return false
        }
    }
    
    /// Проверка валидности формы
    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Полное имя пользователя
    var fullName: String {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        if first.isEmpty && last.isEmpty {
            return "Пользователь"
        }
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    /// Инициалы пользователя
    var initials: String {
        let first = firstName.first.map { String($0).uppercased() } ?? ""
        let last = lastName.first.map { String($0).uppercased() } ?? ""
        if first.isEmpty && last.isEmpty {
            return "?"
        }
        return "\(first)\(last)"
    }
    
    /// Тариф активен
    var isTarifActive: Bool {
        user?.isTarifActive ?? false
    }
    
    /// Практика доступна
    var isPracticeAvailable: Bool {
        user?.practiceAvailable ?? false
    }
}

// MARK: - Response Models

struct UserProfileResponse: Codable {
    let message: String?
    let data: UserProfile?
}

struct UserProfile: Codable {
    let id: Int?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var type: String?
    let pushId: String?
    let joinedAt: String?
    let practiceAvailable: Bool?
    let isTarifActive: Bool?
    let blockBannerTarif: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email, phone, type
        case pushId = "push_id"
        case joinedAt = "joined_at"
        case practiceAvailable = "practice_available"
        case isTarifActive = "is_tarif_active"
        case blockBannerTarif = "block_banner_tarif"
    }
}

struct SimpleResponse: Codable {
    let message: String?
    let success: Bool?
    let status: String?
}

