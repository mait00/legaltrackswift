//
//  Case.swift
//  LegalTrack
//
//  Created on 2024
//

import Foundation

private let isCaseModelVerboseLoggingEnabled = false

private func caseModelDebugLog(_ message: @autoclosure () -> String) {
    guard isCaseModelVerboseLoggingEnabled else { return }
    print(message())
}

/// Универсальный тип для декодирования любых JSON значений
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictionary as [String: Any]:
            let codableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(codableDictionary)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

/// Модель дела
struct LegalCase: Identifiable {
    let id: Int
    let title: String? // Made optional based on logs
    let value: String? // Made optional - can be null in API
    let name: String? // Added 'name' field from logs
    let description: String?
    let isSouRaw: Bool? // СОЮ дело (из API)
    let createdAt: String? // Made optional - can be missing
    let updatedAt: String? // Made optional
    let status: String?
    let companyId: Int?
    let lastEvent: String? // Added from logs
    let totalEvets: String? // Added from logs, type String
    let subscribed: Bool? // Added from logs
    let mutedSide: [String]? // Added from logs
    let mutedAll: Bool? // Added from logs
    let new: Int? // Added from logs
    let folder: String? // Added from logs
    let favorites: Bool? // Added from logs
    let cardLink: String? // Added from logs
    let link: String? // Added from logs
    let sidePl: String? // Added from logs
    let sideDf: CodableValue? // Added from logs, can be String or Array
    let courtName: String? // Added from logs
    let city: String? // Added from logs

    enum CodingKeys: String, CodingKey {
        case id, title, value, name, description, status, folder, favorites, link, city
        case isSouRaw = "is_sou"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case companyId = "company_id"
        case lastEvent = "last_event"
        case totalEvets = "total_evets"
        case subscribed
        case mutedSide = "muted_side"
        case mutedAll = "muted_all"
        case new
        case cardLink = "card-link"
        // sidePl и sideDf будут автоматически конвертированы из side_pl и side_df через .convertFromSnakeCase
        case sidePl
        case sideDf
        case courtName = "court_name"
    }
    
    /// Определить тип суда: true = СОЮ, false = АС
    /// Сначала пробуем из API, затем определяем по номеру дела
    var isSou: Bool {
        // Если есть значение из API - используем его
        if let sou = isSouRaw {
            return sou
        }
        // Fallback: определяем по номеру дела
        // Арбитражные дела имеют формат "А40-XXXXX/YYYY" (начинаются с буквы + цифры города)
        // СОЮ имеют другой формат (обычно цифры)
        guard let caseNumber = value ?? name else {
            return false // По умолчанию - арбитраж
        }
        // Арбитражные дела начинаются с буквы (А, Ф, и т.д.) + цифры
        let pattern = "^[АA]\\d+-"
        if let _ = caseNumber.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
            return false // Это арбитражное дело
        }
        // Если содержит кириллицу в середине (например, "2-1234/2024") - скорее СОЮ
        let souPattern = "^\\d+-\\d+/\\d+"
        if let _ = caseNumber.range(of: souPattern, options: .regularExpression, range: nil, locale: nil) {
            return true // Это дело СОЮ
        }
        // По умолчанию - арбитраж
        return false
    }
    
    var displayTitle: String {
        return title ?? name ?? value ?? "Дело №\(id)"
    }
    
    var formattedDate: String {
        guard let createdAt = createdAt else {
            return "Дата неизвестна"
        }
        if let date = createdAt.toDate() {
            return date.formatted(style: .medium)
        }
        return createdAt
    }
}

// MARK: - Hashable conformance для NavigationLink
extension LegalCase: Hashable {
    static func == (lhs: LegalCase, rhs: LegalCase) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable conformance с поддержкой разных типов is_sou
extension LegalCase: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        companyId = try container.decodeIfPresent(Int.self, forKey: .companyId)
        lastEvent = try container.decodeIfPresent(String.self, forKey: .lastEvent)
        totalEvets = try container.decodeIfPresent(String.self, forKey: .totalEvets)
        subscribed = try container.decodeIfPresent(Bool.self, forKey: .subscribed)
        mutedSide = try container.decodeIfPresent([String].self, forKey: .mutedSide)
        mutedAll = try container.decodeIfPresent(Bool.self, forKey: .mutedAll)
        new = try container.decodeIfPresent(Int.self, forKey: .new)
        folder = try container.decodeIfPresent(String.self, forKey: .folder)
        favorites = try container.decodeIfPresent(Bool.self, forKey: .favorites)
        cardLink = try container.decodeIfPresent(String.self, forKey: .cardLink)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        
        // Декодируем sidePl (автоматически конвертируется из side_pl через .convertFromSnakeCase)
        sidePl = try container.decodeIfPresent(String.self, forKey: .sidePl)
        if let sidePl = sidePl {
            caseModelDebugLog("✅ [LegalCase] Decoded sidePl: '\(sidePl)' for case \(value ?? "unknown")")
        } else {
            caseModelDebugLog("⚠️ [LegalCase] sidePl is nil for case \(value ?? "unknown")")
        }
        
        // Декодируем sideDf (автоматически конвертируется из side_df через .convertFromSnakeCase)
        sideDf = try container.decodeIfPresent(CodableValue.self, forKey: .sideDf)
        if let sideDf = sideDf {
            caseModelDebugLog("✅ [LegalCase] Decoded sideDf for case \(value ?? "unknown"): string='\(sideDf.stringValue ?? "nil")', arrayCount=\(sideDf.arrayValue?.count ?? 0)")
        } else {
            caseModelDebugLog("⚠️ [LegalCase] sideDf is nil for case \(value ?? "unknown")")
        }
        
        courtName = try container.decodeIfPresent(String.self, forKey: .courtName)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        
        // Декодируем is_sou с поддержкой разных типов (Bool, Int, String)
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .isSouRaw) {
            isSouRaw = boolValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .isSouRaw) {
            isSouRaw = intValue != 0
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .isSouRaw) {
            isSouRaw = stringValue.lowercased() == "true" || stringValue == "1"
        } else {
            isSouRaw = nil
        }
    }
}

/// Модель компании
struct Company: Codable, Identifiable {
    let id: Int
    let value: String? // Made optional - can be null in API
    let inn: String? // Added from logs
    let name: String
    let description: String?
    let createdAt: String? // Made optional - can be missing
    let lastEvent: String? // Added from logs
    let totalCases: String? // Added from logs, type String
    let new: Int? // Added from logs
    let status: String? // Added from logs
    let nameCustom: String? // Added from logs

    enum CodingKeys: String, CodingKey {
        case id, value, inn, name, description, status
        case createdAt = "created_at"
        case lastEvent = "last_event"
        case totalCases = "total_cases"
        case new
        case nameCustom = "name_custom"
    }
    
    /// Инициализатор для создания компании из данных
    init(
        id: Int,
        value: String?,
        inn: String?,
        name: String,
        description: String?,
        createdAt: String?,
        lastEvent: String?,
        totalCases: String?,
        new: Int?,
        status: String?,
        nameCustom: String?
    ) {
        self.id = id
        self.value = value
        self.inn = inn
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.lastEvent = lastEvent
        self.totalCases = totalCases
        self.new = new
        self.status = status
        self.nameCustom = nameCustom
    }
}

/// Модель ключевого слова
struct Keyword: Codable, Identifiable {
    let id: Int
    let value: String
    let createdAt: String?
    let lastEvent: String?
    let totalCases: String?
    let sides: String?
    let courts: [String]?
    let categories: [String]?
    let instances: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, value, sides, courts, categories, instances
        case createdAt = "created_at"
        case lastEvent = "last_event"
        case totalCases = "total_cases"
    }
}

/// Ответ со списком дел
struct CasesResponse: Codable {
    let cases: [LegalCase]
    let total: Int?
}

/// Ответ со списком компаний
struct CompaniesResponse: Codable {
    let companies: [Company]
    let total: Int?
}

/// Ответ со всеми подписками
struct SubscriptionsResponse: Codable {
    let message: String? // Added from logs
    let data: SubscriptionsData?
    let casesArray: [LegalCase]? // Прямой массив дел (если API возвращает так) - используем casesArray чтобы избежать конфликта
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case casesArray = "cases"
    }
    
    struct SubscriptionsData: Codable {
        let nestedData: NestedData? // Вложенная структура (если API возвращает data.data)
        let cases: [LegalCase]?
        let companies: [Company]?
        let keywords: [Keyword]?
        
        enum CodingKeys: String, CodingKey {
            case nestedData = "data"
            case cases
            case companies
            case keywords
        }
        
        struct NestedData: Codable {
            let cases: [LegalCase]?
            let companies: [Company]?
            let keywords: [Keyword]?
        }
    }
    
    // Извлекаем дела из разных вариантов структуры ответа
    var cases: [LegalCase] {
        // Вариант 1: прямой массив cases
        if let directCases = casesArray, !directCases.isEmpty {
            return directCases
        }
        // Вариант 2: data.cases
        if let dataCases = data?.cases, !dataCases.isEmpty {
            return dataCases
        }
        // Вариант 3: data.data.cases
        if let nestedCases = data?.nestedData?.cases, !nestedCases.isEmpty {
            return nestedCases
        }
        return []
    }
    
    var companies: [Company] {
        // Вариант 1: data.companies
        if let dataCompanies = data?.companies, !dataCompanies.isEmpty {
            return dataCompanies
        }
        // Вариант 2: data.data.companies
        if let nestedCompanies = data?.nestedData?.companies, !nestedCompanies.isEmpty {
            return nestedCompanies
        }
        return []
    }
    
    var keywords: [Keyword] {
        data?.keywords ?? data?.nestedData?.keywords ?? []
    }
}

/// Значение, которое может быть строкой, массивом или null (для sideDf)
struct CodableValue: Codable {
    var stringValue: String?
    var arrayValue: [SideDFItem]?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Проверяем nil
        if container.decodeNil() {
            stringValue = nil
            arrayValue = nil
            caseModelDebugLog("✅ [CodableValue] Decoded as nil")
            return
        }
        
        // Пробуем декодировать как строку
        if let string = try? container.decode(String.self) {
            stringValue = string
            arrayValue = nil
            caseModelDebugLog("✅ [CodableValue] Decoded as String: '\(string)'")
            return
        }
        
        // Пробуем декодировать как массив SideDFItem напрямую
        // SideDFItem теперь имеет кастомный init, который обрабатывает null
        if let array = try? container.decode([SideDFItem].self) {
            arrayValue = array.isEmpty ? nil : array
            stringValue = nil
            caseModelDebugLog("✅ [CodableValue] Decoded as Array: \(array.count) items")
            return
        }
        
        // Пробуем декодировать как массив FlexibleSideDFItem (с более гибкой обработкой null)
        if let array = try? container.decode([FlexibleSideDFItem].self) {
            let items = array.map { $0.toSideDFItem() }
            arrayValue = items.isEmpty ? nil : items
            stringValue = nil
            caseModelDebugLog("✅ [CodableValue] Decoded as FlexibleArray: \(items.count) items")
            return
        }
        
        // Если ничего не сработало, устанавливаем nil
        stringValue = nil
        arrayValue = nil
        caseModelDebugLog("⚠️ [CodableValue] Could not decode value, setting to nil")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = stringValue {
            try container.encode(string)
        } else if let array = arrayValue {
            try container.encode(array)
        } else {
            try container.encodeNil()
        }
    }
}

/// Элемент массива sideDf
struct SideDFItem: Codable {
    let sideType: SideTypeValue? // Can be String or Int
    let nameSide: String?
    let inn: String?
    let kpp: String?
    let ogrn: String?
    let ogrnip: String?

    enum CodingKeys: String, CodingKey {
        case sideType = "sideType"
        case nameSide = "nameSide"
        case inn, kpp, ogrn, ogrnip
    }
    
    /// Инициализатор с параметрами (для создания из FlexibleSideDFItem)
    init(sideType: SideTypeValue?, nameSide: String?, inn: String?, kpp: String?, ogrn: String?, ogrnip: String?) {
        self.sideType = sideType
        self.nameSide = nameSide
        self.inn = inn
        self.kpp = kpp
        self.ogrn = ogrn
        self.ogrnip = ogrnip
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем sideType (может быть String или Int)
        if let sideTypeValue = try? container.decode(SideTypeValue.self, forKey: .sideType) {
            sideType = sideTypeValue
        } else {
            sideType = nil
        }
        
        // Декодируем nameSide (может быть String или null)
        nameSide = try container.decodeIfPresent(String.self, forKey: .nameSide)
        
        // Декодируем остальные поля
        inn = try container.decodeIfPresent(String.self, forKey: .inn)
        kpp = try container.decodeIfPresent(String.self, forKey: .kpp)
        ogrn = try container.decodeIfPresent(String.self, forKey: .ogrn)
        ogrnip = try container.decodeIfPresent(String.self, forKey: .ogrnip)
    }
}

/// Гибкий элемент sideDf для обработки null значений
/// Используется как fallback когда SideDFItem не может декодироваться
private struct FlexibleSideDFItem: Decodable {
    let sideType: FlexibleValue?
    let nameSide: FlexibleValue?
    let inn: String?
    let kpp: String?
    let ogrn: String?
    let ogrnip: String?
    
    func toSideDFItem() -> SideDFItem {
        var sideTypeValue: SideTypeValue? = nil
        if let st = sideType {
            if let intVal = st.intValue {
                sideTypeValue = SideTypeValue(intValue: intVal)
            } else if let strVal = st.stringValue {
                sideTypeValue = SideTypeValue(stringValue: strVal)
            }
        }
        
        return SideDFItem(
            sideType: sideTypeValue,
            nameSide: nameSide?.stringValue,
            inn: inn,
            kpp: kpp,
            ogrn: ogrn,
            ogrnip: ogrnip
        )
    }
}

/// Гибкое значение для обработки null, string или int
private struct FlexibleValue: Decodable {
    var stringValue: String?
    var intValue: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            stringValue = nil
            intValue = nil
            return
        }
        
        if let int = try? container.decode(Int.self) {
            intValue = int
            stringValue = nil
        } else if let string = try? container.decode(String.self) {
            stringValue = string
            intValue = nil
        } else {
            stringValue = nil
            intValue = nil
        }
    }
}

/// Значение sideType может быть строкой или числом
struct SideTypeValue: Codable {
    var stringValue: String?
    var intValue: Int?
    
    init(intValue: Int) {
        self.intValue = intValue
        self.stringValue = nil
    }
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            intValue = int
        } else if let string = try? container.decode(String.self) {
            stringValue = string
        } else {
            // Если не удалось декодировать, оставляем nil
            intValue = nil
            stringValue = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = intValue {
            try container.encode(int)
        } else if let string = stringValue {
            try container.encode(string)
        }
    }
}

// MARK: - Detail Case Response

/// Ответ API detail-case
struct CaseDetailResponse: Codable {
    let message: String?
    let data: CaseDetailData?
}

/// Данные детального дела
struct CaseDetailData: Codable {
    let id: Int?
    let name: String?
    let value: String? // Номер дела
    let status: String?
    let statusKind: String?
    let isSou: Bool?
    let type: String? // Вид спора
    let kind: String? // Категория
    let courts: String?
    let link: String?
    let cardLink: String?
    let caseDur: String? // Длительность
    let startedDate: String?
    let caseDate: String?
    let addedDate: String?
    let category: String?
    
    // Стороны
    let sides: CaseSides?
    let sidePl: [SideDFItem]?
    let sideDf: [SideDFItem]?
    let plaintiffs: String?
    let defendants: String?
    let third: String?
    let others: String?
    
    // Информация о заседании
    let nearestSession: NearestSession?
    let shortInfo: ShortInfo?
    
    // Дополнительные поля для СОЮ дел
    let judge: String?
    let courtName: String?
    
    // Инстанции (арбитраж) - массив для АС
    let instances: [CaseInstance]?
    
    // Инстанции для СОЮ - объект с ключами "История статусов", "Движение дела", "События", "Судебные акты"
    let instancesDict: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, value, status, type, kind, courts, link, category
        case statusKind = "status_kind"
        case isSou = "is_sou"
        case cardLink = "card-link"
        case caseDur = "case-dur"
        case startedDate = "started-date"
        case caseDate = "case-date"
        case addedDate = "added_date"
        case sides
        case sidePl = "side_pl"
        case sideDf = "side_df"
        case plaintiffs, defendants, third, others
        case nearestSession = "nearest_session"
        case shortInfo = "short_info"
        case instances
        case judge
        case courtName = "court_name"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        statusKind = try container.decodeIfPresent(String.self, forKey: .statusKind)
        isSou = try container.decodeIfPresent(Bool.self, forKey: .isSou)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        courts = try container.decodeIfPresent(String.self, forKey: .courts)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        cardLink = try container.decodeIfPresent(String.self, forKey: .cardLink)
        caseDur = try container.decodeIfPresent(String.self, forKey: .caseDur)
        startedDate = try container.decodeIfPresent(String.self, forKey: .startedDate)
        caseDate = try container.decodeIfPresent(String.self, forKey: .caseDate)
        addedDate = try container.decodeIfPresent(String.self, forKey: .addedDate)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        sides = try container.decodeIfPresent(CaseSides.self, forKey: .sides)
        sidePl = try container.decodeIfPresent([SideDFItem].self, forKey: .sidePl)
        sideDf = try container.decodeIfPresent([SideDFItem].self, forKey: .sideDf)
        plaintiffs = try container.decodeIfPresent(String.self, forKey: .plaintiffs)
        defendants = try container.decodeIfPresent(String.self, forKey: .defendants)
        third = try container.decodeIfPresent(String.self, forKey: .third)
        others = try container.decodeIfPresent(String.self, forKey: .others)
        nearestSession = try container.decodeIfPresent(NearestSession.self, forKey: .nearestSession)
        shortInfo = try container.decodeIfPresent(ShortInfo.self, forKey: .shortInfo)
        judge = try container.decodeIfPresent(String.self, forKey: .judge)
        courtName = try container.decodeIfPresent(String.self, forKey: .courtName)
        
        // Пытаемся декодировать instances как массив (для АС)
        if let instancesArray = try? container.decode([CaseInstance].self, forKey: .instances) {
            instances = instancesArray
            instancesDict = nil
        } else {
            // Для СОЮ - это объект (словарь) с ключами "История статусов", "Движение дела", "События", "Судебные акты"
            // Декодируем как словарь через JSONSerialization
            if let instancesValue = try? container.decode(AnyCodable.self, forKey: .instances),
               let dict = instancesValue.value as? [String: Any] {
                instances = nil
                instancesDict = dict
                caseModelDebugLog("📋 [CaseDetailData] Decoded instances as dictionary (SOY case) with keys: \(dict.keys.joined(separator: ", "))")
            } else {
                instances = nil
                instancesDict = nil
            }
        }
    }
    
    /// Получить номер дела
    var caseNumber: String? {
        shortInfo?.caseNumber ?? value
    }
    
    /// Получить суд
    var court: String? {
        courtName ?? shortInfo?.court ?? courts
    }
    
    /// Получить судью
    var judgeName: String? {
        judge ?? shortInfo?.judge ?? nearestSession?.judge
    }
}

/// Стороны дела
struct CaseSides: Codable {
    let Plaintiffs: [SideParty]?
    let Defendants: [SideParty]?
    let Third: [SideParty]?
    let Others: [SideParty]?
}

/// Участник дела
struct SideParty: Codable {
    let Id: String?
    let Name: String?
    let Address: String?
    let INN: String?
    let OGRN: String?
    let BirthDate: String?
    let SideType: Int?
    
    var displayName: String {
        Name ?? "Не указано"
    }
    
    // Mapping для удобства
    var Inn: String? { INN }
    var Ogrn: String? { OGRN }
}

/// Информация о ближайшем заседании
struct NearestSession: Codable {
    let date: String?
    let judge: String?
    let cabinet: String?
}

/// Краткая информация о деле
struct ShortInfo: Codable {
    let caseNumber: String?
    let court: String?
    let judge: String?
    let hearingDate: String?
    
    enum CodingKeys: String, CodingKey {
        case caseNumber = "case"
        case court, judge, hearingDate
    }
}

/// Инстанция арбитражного дела
struct CaseInstance: Codable {
    let instanceName: String?
    let name: String?
    let data: InstanceData?
    let dataCourt: String? // Код суда
    let dataId: String? // ID инстанции
    let courtName: String? // Название суда
    let caseNumber: String? // Номер дела в инстанции
    
    enum CodingKeys: String, CodingKey {
        case instanceName = "instance-name"
        case name, data
        case dataCourt = "data-court"
        case dataId = "data-id"
        case courtName = "court-name"
        case caseNumber = "case-number"
    }
    
    var displayName: String {
        instanceName ?? name ?? "Инстанция"
    }
}

/// Данные инстанции
struct InstanceData: Codable {
    let Result: InstanceResult?
}

/// Результат инстанции
struct InstanceResult: Codable {
    let Items: [InstanceItem]?
}

/// Элемент инстанции (документ/событие)
struct InstanceItem: Codable {
    let Id: String? // Может быть пустая строка или UUID
    let CaseId: String?
    let InstanceId: String?
    let CourtName: String?
    let CourtTag: String?
    let DisplayDate: String?
    let Date: String?
    let DocumentTypeName: String?
    let AdditionalInfo: String?
    let DecisionTypeName: String?
    let FileName: String?
    let Judges: [JudgeInfo]?
    let Declarers: [DeclarerInfo]?
    let PublishDisplayDate: String?
    let ContentTypes: [String]?
    let ClaimSum: Double?
    let RecoverySum: Double?
    let IsAct: Bool?
    let HearingPlace: String?
    let InstanceLevel: Int?
}

/// Информация о судье
struct JudgeInfo: Codable {
    let Name: String?
    let Role: String?
}

/// Информация о заявителе
struct DeclarerInfo: Codable {
    let Id: String?
    let OrganizationId: String?
    let Organization: String?
    let Address: String?
    let Inn: String?
    let Ogrn: String?
    let declarerType: Int?
    
    enum CodingKeys: String, CodingKey {
        case Id, OrganizationId, Organization, Address, Inn, Ogrn
        case declarerType = "Type"
    }
    
    var typeString: String {
        declarerType == 0 ? "Истец" : "Ответчик"
    }
}

// MARK: - Normalized Case Detail (для UI)

/// Нормализованные данные дела для отображения
struct NormalizedCaseDetail {
    let id: Int
    let number: String
    let name: String?
    let category: String?
    let type: String?
    let kind: String?
    let court: String?
    let judge: String?
    let status: String?
    let duration: String?
    let startDate: Date?
    let isSou: Bool
    let link: String?
    let cardLink: String?
    
    // Стороны
    var plaintiffs: [ParticipantInfo] = []
    var defendants: [ParticipantInfo] = []
    var third: [ParticipantInfo] = []
    var others: [ParticipantInfo] = []
    
    // Инстанции с документами
    var instances: [NormalizedInstance] = []
    
    // Судебные акты
    var judicialActs: [NormalizedDocument] = []
    
    /// Цепочка номеров дел по инстанциям (например: Ф05-11221/2017 ← 09АП-6435/2017 ← А40-209823/2016)
    var caseNumbersChain: String {
        let numbers = instances.compactMap { $0.caseNumber }.filter { !$0.isEmpty }
        if numbers.isEmpty {
            return number
        }
        // Сортируем по инстанциям (кассация → апелляция → первая)
        return numbers.joined(separator: " ← ")
    }
}

/// Информация об участнике
struct ParticipantInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let inn: String?
    let ogrn: String?
}

/// Нормализованная инстанция
struct NormalizedInstance: Identifiable {
    let id = UUID()
    let name: String
    let court: String
    let caseNumber: String? // Номер дела в этой инстанции
    let date: String? // Дата рассмотрения
    var documents: [NormalizedDocument] = []
}

/// Нормализованный документ
struct NormalizedDocument: Identifiable {
    let id = UUID()
    let date: Date?
    let displayDate: String?
    let publishDate: String? // Дата публикации
    let type: String?
    let description: String?
    let judges: [String]
    let declarers: [String] // Организации-подателей
    let decision: String?
    let url: String?
    let courtName: String?
    let isAct: Bool // Является ли судебным актом (для иконки PDF)
    let contentTypes: [String] // Типы контента (pdf и т.д.)
    let documentId: String? // ID документа для формирования URL
    let caseIdKad: String? // CaseId от kad.arbitr.ru
    
    /// Полный URL для скачивания PDF (приоритет: API /subs/get-pdf)
    var pdfURL: String? {
        // Если url уже полный - возвращаем его
        if let url = url, url.hasPrefix("http") {
            caseModelDebugLog("📄 [PDF URL] Using direct URL: \(url)")
            return url
        }
        
        // Приоритет 1: Через API /subs/get-pdf (основной источник)
        if let caseId = caseIdKad, !caseId.isEmpty,
           let docId = documentId, !docId.isEmpty, docId != "" {
            // URL-кодируем параметры для безопасности
            let encodedCaseId = caseId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? caseId
            let encodedDocId = docId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? docId
            let apiURL = "\(AppConstants.API.baseURL)/subs/get-pdf?case_id=\(encodedCaseId)&document_id=\(encodedDocId)"
            caseModelDebugLog("📄 [PDF URL] Generated via API /subs/get-pdf: \(apiURL)")
            return apiURL
        }
        
        // Приоритет 2: Если FileName начинается с / - это путь к API
        if let fileName = url, !fileName.isEmpty, fileName.hasPrefix("/") {
            let apiURL = "\(AppConstants.API.baseURL)\(fileName)"
            caseModelDebugLog("📄 [PDF URL] Generated from FileName path: \(apiURL)")
            return apiURL
        }
        
        // Приоритет 3: Через kad.arbitr.ru (резервный вариант)
        if let caseId = caseIdKad, !caseId.isEmpty,
           let docId = documentId, !docId.isEmpty, docId != "" {
            // URL-кодируем для безопасности
            let encodedCaseId = caseId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? caseId
            let encodedDocId = docId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? docId
            let kadURL = "https://kad.arbitr.ru/Document/Pdf/\(encodedCaseId)/\(encodedDocId)?isAddStamp=True"
            caseModelDebugLog("📄 [PDF URL] Generated via kad.arbitr.ru (fallback): \(kadURL)")
            return kadURL
        }
        
        // Приоритет 4: Через kad.arbitr.ru/Kad/PdfDocument/{FileName} (если FileName это UUID)
        if let fileName = url, !fileName.isEmpty {
            // Если FileName выглядит как UUID (содержит дефисы) - пробуем через kad.arbitr.ru
            if fileName.contains("-") && fileName.count > 10 {
                let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                let kadURL = "https://kad.arbitr.ru/Kad/PdfDocument/\(encodedFileName)"
                caseModelDebugLog("📄 [PDF URL] Generated from FileName UUID via kad.arbitr.ru (fallback): \(kadURL)")
                return kadURL
            }
        }
        
        caseModelDebugLog("⚠️ [PDF URL] Cannot generate URL - missing data")
        caseModelDebugLog("   - caseIdKad: \(caseIdKad ?? "nil")")
        caseModelDebugLog("   - documentId: \(documentId ?? "nil")")
        caseModelDebugLog("   - url: \(url ?? "nil")")
        return nil
    }
}

// MARK: - NormalizedCaseDetail Extension

extension NormalizedCaseDetail {
    /// Инициализация из CaseDetailData (ответ API)
    init(from data: CaseDetailData) {
        self.id = data.id ?? 0
        self.number = data.value ?? "Без номера"
        self.name = data.name
        self.category = data.category
        self.type = data.type
        self.kind = data.kind
        self.court = data.court ?? data.courts
        self.judge = data.judgeName // Для СОЮ дел берем напрямую из API
        self.status = data.status
        self.duration = data.caseDur
        self.isSou = data.isSou ?? false
        self.link = data.link
        self.cardLink = data.cardLink
        
        // Парсим дату начала
        if let dateStr = data.startedDate ?? data.caseDate {
            self.startDate = dateStr.toDate()
        } else {
            self.startDate = nil
        }
        
        // Парсим участников из строк (plaintiffs, defendants, etc.)
        if let plaintiffsStr = data.plaintiffs, !plaintiffsStr.isEmpty {
            self.plaintiffs = plaintiffsStr.split(separator: ",").map { name in
                ParticipantInfo(name: String(name).trimmingCharacters(in: .whitespaces), address: nil, inn: nil, ogrn: nil)
            }
        } else if let sidePl = data.sidePl {
            self.plaintiffs = sidePl.map { side in
                ParticipantInfo(name: side.nameSide ?? "Неизвестно", address: nil, inn: side.inn, ogrn: side.ogrn)
            }
        } else if let sides = data.sides?.Plaintiffs {
            self.plaintiffs = sides.map { party in
                ParticipantInfo(name: party.Name ?? "Неизвестно", address: party.Address, inn: party.INN, ogrn: party.OGRN)
            }
        } else {
            self.plaintiffs = []
        }
        
        if let defendantsStr = data.defendants, !defendantsStr.isEmpty {
            self.defendants = defendantsStr.split(separator: ",").map { name in
                ParticipantInfo(name: String(name).trimmingCharacters(in: .whitespaces), address: nil, inn: nil, ogrn: nil)
            }
        } else if let sideDf = data.sideDf {
            self.defendants = sideDf.map { side in
                ParticipantInfo(name: side.nameSide ?? "Неизвестно", address: nil, inn: side.inn, ogrn: side.ogrn)
            }
        } else if let sides = data.sides?.Defendants {
            self.defendants = sides.map { party in
                ParticipantInfo(name: party.Name ?? "Неизвестно", address: party.Address, inn: party.INN, ogrn: party.OGRN)
            }
        } else {
            self.defendants = []
        }
        
        if let thirdStr = data.third, !thirdStr.isEmpty {
            self.third = thirdStr.split(separator: ",").map { name in
                ParticipantInfo(name: String(name).trimmingCharacters(in: .whitespaces), address: nil, inn: nil, ogrn: nil)
            }
        } else if let sides = data.sides?.Third {
            self.third = sides.map { party in
                ParticipantInfo(name: party.Name ?? "Неизвестно", address: party.Address, inn: party.INN, ogrn: party.OGRN)
            }
        } else {
            self.third = []
        }
        
        if let othersStr = data.others, !othersStr.isEmpty {
            self.others = othersStr.split(separator: ",").map { name in
                ParticipantInfo(name: String(name).trimmingCharacters(in: .whitespaces), address: nil, inn: nil, ogrn: nil)
            }
        } else if let sides = data.sides?.Others {
            self.others = sides.map { party in
                ParticipantInfo(name: party.Name ?? "Неизвестно", address: party.Address, inn: party.INN, ogrn: party.OGRN)
            }
        } else {
            self.others = []
        }
        
        // Парсим инстанции
        if let instances = data.instances {
            self.instances = instances.map { instance in
                var docs: [NormalizedDocument] = []
                var instanceCourt = ""
                var instanceCaseNumber: String? = nil
                var instanceDate: String? = nil
                
                // Извлекаем номер дела и суд из инстанции
                instanceCourt = instance.courtName ?? ""
                instanceCaseNumber = instance.caseNumber
                
                if let items = instance.data?.Result?.Items {
                    // Если нет в инстанции, берём из первого документа
                    if let firstItem = items.first {
                        if instanceCourt.isEmpty {
                            instanceCourt = firstItem.CourtName ?? ""
                        }
                        instanceDate = firstItem.DisplayDate
                    }
                    
                    docs = items.map { item in
                        // Определяем, является ли документ судебным актом
                        let docType = (item.DocumentTypeName ?? "").lowercased()
                        let isJudicialAct = docType.contains("определение") ||
                                           docType.contains("решение") ||
                                           docType.contains("постановление") ||
                                           item.IsAct == true
                        
                        // Извлекаем организации-подателей
                        let declarerNames = item.Declarers?.compactMap { $0.Organization } ?? []
                        
                        // Отладка PDF данных
                        caseModelDebugLog("📄 [Document] Id=\(item.Id ?? "nil"), CaseId=\(item.CaseId ?? "nil"), FileName=\(item.FileName ?? "nil"), IsAct=\(item.IsAct ?? false)")
                        
                        return NormalizedDocument(
                            date: item.DisplayDate?.toDate(),
                            displayDate: item.DisplayDate,
                            publishDate: item.PublishDisplayDate,
                            type: item.DocumentTypeName,
                            description: item.AdditionalInfo ?? item.DecisionTypeName,
                            judges: item.Judges?.compactMap { $0.Name } ?? [],
                            declarers: declarerNames,
                            decision: item.DecisionTypeName,
                            url: item.FileName,
                            courtName: item.CourtName,
                            isAct: isJudicialAct,
                            contentTypes: item.ContentTypes ?? [],
                            documentId: item.Id,
                            caseIdKad: item.CaseId
                        )
                    }
                }
                
                return NormalizedInstance(
                    name: instance.displayName,
                    court: instanceCourt,
                    caseNumber: instanceCaseNumber,
                    date: instanceDate,
                    documents: docs
                )
            }
        } else if let instancesDict = data.instancesDict {
            // Для СОЮ дел - instances это объект с ключами "История статусов", "Движение дела", "События", "Судебные акты"
            caseModelDebugLog("📋 [NormalizedCaseDetail] Parsing SOY case instances as dictionary")
            
            var soyInstances: [NormalizedInstance] = []
            
            // Парсим "События" (массив событий)
            if let eventsArray = instancesDict["События"] as? [[String: Any]] {
                var events: [NormalizedDocument] = []
                
                for eventDict in eventsArray {
                    let dateStr = eventDict["date"] as? String
                    let timeStr = eventDict["time"] as? String
                    let header = eventDict["header"] as? String ?? ""
                    let text = eventDict["text"] as? String
                    
                    // Формируем дату из date и time
                    var displayDate: String? = nil
                    if let date = dateStr {
                        if let time = timeStr, !time.isEmpty {
                            displayDate = "\(date) \(time)"
                        } else {
                            displayDate = date
                        }
                    }
                    
                    events.append(NormalizedDocument(
                        date: displayDate?.toDate(),
                        displayDate: displayDate,
                        publishDate: nil,
                        type: header,
                        description: text,
                        judges: [],
                        declarers: [],
                        decision: nil,
                        url: nil,
                        courtName: nil,
                        isAct: false,
                        contentTypes: [],
                        documentId: nil,
                        caseIdKad: nil
                    ))
                }
                
                if !events.isEmpty {
                    soyInstances.append(NormalizedInstance(
                        name: "События",
                        court: data.courts ?? "",
                        caseNumber: data.value,
                        date: events.first?.displayDate,
                        documents: events
                    ))
                }
            }
            
            // Парсим "Судебные акты" (массив актов)
            if let actsArray = instancesDict["Судебные акты"] as? [[String: Any]] {
                var acts: [NormalizedDocument] = []
                
                for actDict in actsArray {
                    let dateStr = actDict["date"] as? String
                    let timeStr = actDict["time"] as? String
                    let header = actDict["header"] as? String ?? ""
                    let text = actDict["text"] as? String
                    
                    var displayDate: String? = nil
                    if let date = dateStr {
                        if let time = timeStr, !time.isEmpty {
                            displayDate = "\(date) \(time)"
                        } else {
                            displayDate = date
                        }
                    }
                    
                    acts.append(NormalizedDocument(
                        date: displayDate?.toDate(),
                        displayDate: displayDate,
                        publishDate: nil,
                        type: header,
                        description: text,
                        judges: [],
                        declarers: [],
                        decision: nil,
                        url: nil,
                        courtName: nil,
                        isAct: true,
                        contentTypes: [],
                        documentId: nil,
                        caseIdKad: nil
                    ))
                }
                
                if !acts.isEmpty {
                    soyInstances.append(NormalizedInstance(
                        name: "Судебные акты",
                        court: data.courts ?? "",
                        caseNumber: data.value,
                        date: acts.first?.displayDate,
                        documents: acts
                    ))
                }
            }
            
            self.instances = soyInstances
            caseModelDebugLog("📋 [NormalizedCaseDetail] Parsed \(soyInstances.count) SOY instances with \(soyInstances.reduce(0) { $0 + $1.documents.count }) documents")
        } else {
            self.instances = []
        }
        
        self.judicialActs = []
    }
}
