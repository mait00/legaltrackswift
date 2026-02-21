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
                self.firstName = (userData.firstName ?? "").personNameCased()
                self.lastName = (userData.lastName ?? "").personNameCased()
                self.email = userData.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.phone = userData.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if let type = userData.type {
                    self.userType = UserType(rawValue: type) ?? .lawyer
                }

                // Keep local user in sync with normalized fields for correct display.
                self.user?.firstName = self.firstName
                self.user?.lastName = self.lastName
                self.user?.email = self.email
                self.user?.phone = self.phone
                
                print("✅ [Profile] Loaded profile: \(fullName), type: \(userType.displayName), email: \(email)")
                isLoading = false
                errorMessage = nil
            } else {
                print("⚠️ [Profile] No data in response")
                isLoading = false
                errorMessage = "Не удалось загрузить данные профиля"
            }
        } catch is CancellationError {
            isLoading = false
            // Игнорируем отмену (например, при повторном refresh), чтобы не пугать пользователя ложной ошибкой.
            errorMessage = nil
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

        let normalizedFirstName = firstName.personNameCased()
        let normalizedLastName = lastName.personNameCased()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let endpoint = APIEndpoint.editProfile(
                firstName: normalizedFirstName,
                lastName: normalizedLastName,
                email: normalizedEmail,
                type: userType.rawValue
            )

            let response: SimpleResponse = try await apiService.request(
                endpoint: endpoint.path,
                method: .post,
                body: endpoint.body
            )

            if response.success == false {
                throw APIError.serverError(message: response.message ?? "Не удалось сохранить профиль")
            }
            if let status = response.status?.lowercased(),
               ["error", "failed", "failure"].contains(status) {
                throw APIError.serverError(message: response.message ?? "Не удалось сохранить профиль")
            }
            
            isSaving = false
            successMessage = "Профиль сохранён"
            
            // Обновляем локальные данные
            firstName = normalizedFirstName
            lastName = normalizedLastName
            email = normalizedEmail
            user?.firstName = normalizedFirstName
            user?.lastName = normalizedLastName
            user?.email = normalizedEmail
            user?.type = userType.rawValue
            
            return true
        } catch {
            isSaving = false
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось сохранить профиль"
            } else {
                errorMessage = "Не удалось сохранить профиль: \(error.localizedDescription)"
            }
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
        let first = firstName.personNameCased()
        let last = lastName.personNameCased()
        let joined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        if !joined.isEmpty { return joined }

        // Fallbacks when backend didn't return names.
        if let phone = phone.trimmedNonEmpty() {
            return phone.formattedPhone()
        }
        if let email = email.trimmedNonEmpty() {
            return email
        }
        return "Пользователь"
    }
    
    /// Инициалы пользователя
    var initials: String {
        let first = firstName.personNameCased()
        let last = lastName.personNameCased()
        let f = first.first.map { String($0).uppercased() } ?? ""
        let l = last.first.map { String($0).uppercased() } ?? ""
        if !f.isEmpty || !l.isEmpty { return "\(f)\(l)" }
        return "?"
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

struct UserProfileResponse: Decodable {
    let message: String?
    let data: UserProfile?
}

struct UserProfile: Decodable {
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
        case isTariffActive = "is_tariff_active"
        case blockBannerTarif = "block_banner_tarif"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = try decoder.container(keyedBy: DynamicCodingKeys.self)

        id = try c.decodeIfPresent(Int.self, forKey: .id)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        pushId = try c.decodeIfPresent(String.self, forKey: .pushId)
        joinedAt = try c.decodeIfPresent(String.self, forKey: .joinedAt)

        // Some backends may return `firstName/lastName`, or `name/surname`.
        func decodeAnyString(_ keys: [String]) -> String? {
            for k in keys {
                guard let key = DynamicCodingKeys(stringValue: k) else { continue }
                if let v = try? d.decodeIfPresent(String.self, forKey: key) {
                    if let s = v.trimmedNonEmpty() { return s }
                }
            }
            return nil
        }

        if firstName?.trimmedNonEmpty() == nil {
            firstName = decodeAnyString(["firstName", "firstname", "name", "given_name", "givenName"])
        }
        if lastName?.trimmedNonEmpty() == nil {
            lastName = decodeAnyString(["lastName", "lastname", "surname", "family_name", "familyName"])
        }

        // Backend sometimes returns these flags as Bool, 0/1, or "0"/"1".
        func decodeFlexibleBool(_ key: CodingKeys) -> Bool? {
            if let b = try? c.decodeIfPresent(Bool.self, forKey: key) { return b }
            if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return i != 0 }
            if let s = try? c.decodeIfPresent(String.self, forKey: key) {
                let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if ["1", "true", "yes"].contains(v) { return true }
                if ["0", "false", "no"].contains(v) { return false }
            }
            return nil
        }

        practiceAvailable = decodeFlexibleBool(.practiceAvailable)
        // Some backends use `is_tariff_active` (double "f").
        isTarifActive = decodeFlexibleBool(.isTarifActive) ?? decodeFlexibleBool(.isTariffActive)
        blockBannerTarif = decodeFlexibleBool(.blockBannerTarif)
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init?(intValue: Int) { return nil }
}

struct SimpleResponse: Codable {
    let message: String?
    let success: Bool?
    let status: String?
}
