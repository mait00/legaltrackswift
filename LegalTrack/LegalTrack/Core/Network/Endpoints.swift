//
//  Endpoints.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

/// Эндпоинты API
enum APIEndpoint {
    // MARK: - Auth
    case getCode(phone: String)
    case sendCode(phone: String, code: String)
    case getProfile
    case editProfile(firstName: String, lastName: String, email: String, type: String)
    case editPushUID(uid: String)
    case logout
    
    // MARK: - Monitoring
    case getSubscriptions
    case newSubscription(type: String, value: String, sou: Bool)
    case deleteSubscription(id: Int, type: String)
    case detailCase(id: Int)
    case detailCompany(id: Int)
    case detailKeyword(id: Int)
    
    // MARK: - Cases Management
    case searchCases(query: String)
    case renameCase(id: Int, name: String)
    case muteCaseAll(id: Int, muteAll: Bool)
    case muteCaseList(id: Int, mutedList: [String])
    case addNote(id: Int, text: String)
    case updateNote(id: Int, text: String)
    case uploadAudio
    
    // MARK: - Companies Management
    case searchCompanies(query: String)
    case renameCompany(id: Int, name: String)
    
    // MARK: - Keywords
    case editKeyword
    case renameAudio
    
    // MARK: - Notifications
    case getNotifications
    
    // MARK: - Calendar
    case getCalendarEvents
    
    // MARK: - Delays
    case getDelays
    case searchDelay(query: String)
    
    // MARK: - Dictionaries
    case getCategoriesCases
    case getCourts
    case getInstances
    
    // MARK: - Documents
    case getPDF(caseId: String, documentId: String)
    
    // MARK: - Tariffs
    case getUserTarif
    case cancelSubscription
    case validateReceipt(receipt: String, storeType: String, tarif: String)
    
    // MARK: - Chat
    case getMessages
    case newMessage(text: String)
    
    // Legacy placeholder for backward compatibility
    case addCase(value: String, isSou: Bool)
    case removeCase(id: Int)
    
    var path: String {
        switch self {
        // Auth
        case .getCode(let phone):
            let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phone
            return "/auth/get-auth-code?phone=\(encodedPhone)"
        case .sendCode(let phone, let code):
            let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phone
            let encodedCode = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? code
            return "/auth/check-auth-code?phone=\(encodedPhone)&code=\(encodedCode)"
        case .getProfile:
            return "/auth/user-detail"
        case .editProfile:
            return "/auth/edit-profile"
        case .editPushUID:
            return "/auth/edit-push-uid"
        case .logout:
            return "/auth/logout/"
            
        // Monitoring
        case .getSubscriptions:
            return "/subs/get-subscribtions"
        case .newSubscription:
            return "/subs/new-subscribtion"
        case .deleteSubscription(let id, let type):
            return "/subs/delete?id=\(id)&type=\(type)"
        case .detailCase(let id):
            return "/subs/detail-case?id=\(id)"
        case .detailCompany(let id):
            return "/subs/detail-company?id=\(id)"
        case .detailKeyword(let id):
            return "/subs/detail-keyword?id=\(id)"
            
        // Cases Management
        case .searchCases(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/subs/search-cases?q=\(encodedQuery)"
        case .renameCase:
            return "/subs/rename-case"
        case .muteCaseAll, .muteCaseList:
            return "/subs/mute-case-settings"
        case .addNote:
            return "/subs/add-note"
        case .updateNote:
            return "/subs/update-note"
        case .uploadAudio:
            return "/subs/upload-audio" // Placeholder path
        
        // Companies Management
        case .searchCompanies(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/subs/search-companies?q=\(encodedQuery)"
        case .renameCompany:
            return "/subs/rename-company"
            
        // Keywords
        case .editKeyword:
            return "/subs/edit-keyword" // Placeholder path
        case .renameAudio:
            return "/subs/rename-audio" // Placeholder path
            
        // Notifications
        case .getNotifications:
            return "/subs/get-notiffications"
            
        // Calendar
        case .getCalendarEvents:
            return "/subs/get-calendar"
            
        // Delays
        case .getDelays:
            return "/subs/get-delays"
        case .searchDelay(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/subs/search-delay?case_number=\(encodedQuery)"
            
        // Dictionaries
        case .getCategoriesCases:
            return "/subs/get-categories-cases"
        case .getCourts:
            return "/subs/get-courts"
        case .getInstances:
            return "/subs/get-instances"
            
        // Documents
        case .getPDF(let caseId, let documentId):
            return "/subs/get-pdf?case_id=\(caseId)&document_id=\(documentId)"
            
        // Tariffs
        case .getUserTarif:
            return "/api/user-tarif"
        case .cancelSubscription:
            return "/api/user-cancel-subscribtion"
        case .validateReceipt:
            return "/api/validate-receipt"
            
        // Chat
        case .getMessages:
            return "/api/messages"
        case .newMessage:
            return "/api/new-message"
            
        // Legacy cases map to new paths
        case .addCase:
            return "/subs/new-subscribtion"
        case .removeCase(let id):
            return "/subs/delete?id=\(id)&type=case"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        // GET methods
        case .getCode, .sendCode, .getProfile, .getSubscriptions,
             .deleteSubscription, .getNotifications, .getCalendarEvents, .detailCase,
             .searchCases, .searchCompanies, .detailCompany, .detailKeyword,
             .getDelays, .searchDelay, .getCategoriesCases, .getCourts, .getInstances,
             .getPDF, .getUserTarif, .cancelSubscription, .getMessages:
            return .get
            
        // POST methods
        case .editProfile, .editPushUID, .newSubscription, .renameCase, .muteCaseAll,
             .muteCaseList, .addNote, .updateNote, .renameCompany, .editKeyword,
             .renameAudio, .validateReceipt, .newMessage, .uploadAudio, .logout:
            return .post
            
        // Legacy addCase and removeCase mapped to POST/GET appropriately
        case .addCase:
            return .post
        case .removeCase:
            return .get
        }
    }
    
    /// Получить тело запроса для POST запросов
    var body: Encodable? {
        switch self {
        case .newSubscription(let type, let value, let sou):
            return NewSubscriptionRequest(type: type, value: value, sou: sou)
        case .editProfile(let firstName, let lastName, let email, let type):
            return EditProfileRequest(firstName: firstName, lastName: lastName, email: email, type: type)
        case .editPushUID(let uid):
            return EditPushUIDRequest(uid: uid)
        case .renameCase(let id, let name):
            return RenameCaseRequest(id: id, name: name)
        case .muteCaseAll(let id, let muteAll):
            return MuteCaseAllRequest(id: id, mute_all: muteAll)
        case .muteCaseList(let id, let mutedList):
            return MuteCaseListRequest(id: id, muted_list: mutedList)
        case .addNote(let id, let text):
            return NoteRequest(id: id, text: text)
        case .updateNote(let id, let text):
            return NoteRequest(id: id, text: text)
        case .renameCompany(let id, let name):
            return RenameCompanyRequest(id: id, name: name)
        case .validateReceipt(let receipt, let storeType, let tarif):
            return ValidateReceiptRequest(receipt: receipt, store_type: storeType, tarif: tarif)
        case .newMessage(let text):
            return NewMessageRequest(text: text)
            
        // Legacy addCase maps to newSubscription body
        case .addCase(let value, let isSou):
            return NewSubscriptionRequest(type: "case", value: value, sou: isSou)
            
        // Others have no body
        default:
            return nil
        }
    }
}

// MARK: - Request Bodies

struct NewSubscriptionRequest: Codable {
    let type: String
    let value: String
    let sou: Bool
}

struct EditProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case type
    }
}
struct EditPushUIDRequest: Codable {
    let uid: String
}

struct RenameCaseRequest: Codable {
    let id: Int
    let name: String
}

struct MuteCaseAllRequest: Codable {
    let id: Int
    let mute_all: Bool
}

struct MuteCaseListRequest: Codable {
    let id: Int
    let muted_list: [String]
}

struct NoteRequest: Codable {
    let id: Int
    let text: String
}

struct RenameCompanyRequest: Codable {
    let id: Int
    let name: String
}

struct ValidateReceiptRequest: Codable {
    let receipt: String
    let store_type: String
    let tarif: String
}

struct NewMessageRequest: Codable {
    let text: String
}

