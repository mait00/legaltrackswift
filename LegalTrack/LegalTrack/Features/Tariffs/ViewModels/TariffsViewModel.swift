//
//  TariffsViewModel.swift
//  LegalTrack
//
//  Ported from legacy RN tariffs flow:
//  - GET  /api/user-tarif
//  - GET  /api/user-cancel-subscribtion
//  - POST /api/validate-receipt { receipt, store_type, tarif(productId) }
//

import Foundation
import StoreKit

@MainActor
final class TariffsViewModel: ObservableObject {
    @Published private(set) var payload: TariffsPayload?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPurchasing: Bool = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let apiService = APIService.shared

    // Product IDs: backend can activate older and newer SKUs (e.g. lt.prof2).
    private let productIds = ["lt.prof1", "lt.prof2", "lt.prof6", "lt.prof12"]

    func load() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            let response: TariffsResponse = try await apiService.request(
                endpoint: APIEndpoint.getUserTarif.path,
                method: .get
            )
            payload = response.data
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось загрузить тарифы"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancelSubscription() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            let _: SimpleResponse = try await apiService.request(
                endpoint: APIEndpoint.cancelSubscription.path,
                method: .get
            )
            infoMessage = "Подписка отменена"
            await load()
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileShouldRefresh"), object: nil)
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось отменить подписку"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func buy(productId: String) async {
        isPurchasing = true
        errorMessage = nil
        infoMessage = nil
        defer { isPurchasing = false }

        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                throw TariffPurchaseError.productNotFound
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try verificationResult.payloadValue
                await transaction.finish()

                let receipt = try await AppStoreReceipt.base64ReceiptOrRefresh()
                let _: SimpleResponse = try await apiService.request(
                    endpoint: APIEndpoint.validateReceipt(receipt: receipt, storeType: "appstore", tarif: transaction.productID).path,
                    method: .post,
                    body: ValidateReceiptRequest(receipt: receipt, store_type: "appstore", tarif: transaction.productID)
                )

                infoMessage = "Покупка подтверждена"
                await load()
                NotificationCenter.default.post(name: NSNotification.Name("UserProfileShouldRefresh"), object: nil)

            case .pending:
                infoMessage = "Покупка ожидает подтверждения"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            if let e = error as? TariffPurchaseError {
                errorMessage = e.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil
        infoMessage = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            let receipt = try await AppStoreReceipt.base64ReceiptOrRefresh()

            // Try validating receipt against known SKUs (longest first).
            let tryIds = ["lt.prof12", "lt.prof6", "lt.prof2", "lt.prof1"]
            var validated = false

            for id in tryIds {
                do {
                    let _: SimpleResponse = try await apiService.request(
                        endpoint: APIEndpoint.validateReceipt(receipt: receipt, storeType: "appstore", tarif: id).path,
                        method: .post,
                        body: ValidateReceiptRequest(receipt: receipt, store_type: "appstore", tarif: id)
                    )
                    validated = true
                    break
                } catch {
                    continue
                }
            }

            if validated {
                infoMessage = "Покупки восстановлены"
                await load()
                NotificationCenter.default.post(name: NSNotification.Name("UserProfileShouldRefresh"), object: nil)
            } else {
                throw TariffPurchaseError.restoreFailed
            }
        } catch {
            if let e = error as? TariffPurchaseError {
                errorMessage = e.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func productId(for plan: TariffPlan) -> String? {
        if let m = plan.month {
            switch m {
            case 1: return "lt.prof1"
            case 2: return "lt.prof2"
            case 6: return "lt.prof6"
            case 12: return "lt.prof12"
            default: break
            }
        }
        return plan.productId
    }

    var knownProductIds: [String] { productIds }
}

// MARK: - API Models

struct TariffsResponse: Decodable {
    let message: String?
    let data: TariffsPayload?
}

struct TariffsPayload: Decodable {
    let active: Bool?
    let header: String?
    let text: String?
    let tarifs: [TariffPlan]?

    enum CodingKeys: String, CodingKey {
        case active
        case isActive = "is_active"
        case isTarifActive = "is_tarif_active"
        case isTariffActive = "is_tariff_active"
        case header, text, tarifs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

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

        // Backend may return active as Bool / 0-1 / "0"-"1".
        active =
            decodeFlexibleBool(.active) ??
            decodeFlexibleBool(.isActive) ??
            decodeFlexibleBool(.isTarifActive) ??
            decodeFlexibleBool(.isTariffActive)

        header = try c.decodeIfPresent(String.self, forKey: .header)
        text = try c.decodeIfPresent(String.self, forKey: .text)
        tarifs = try c.decodeIfPresent([TariffPlan].self, forKey: .tarifs)
    }
}

struct TariffPlan: Decodable, Identifiable, Hashable {
    var id: String { "\(month ?? -1)-\(name ?? "")" }

    let name: String?
    let price: String?
    let month: Int?
    let url: String?
    let productId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case price
        case month
        case url
        case productId = "product_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        productId = try c.decodeIfPresent(String.self, forKey: .productId)

        // price can be string or number
        if let s = try? c.decodeIfPresent(String.self, forKey: .price) {
            price = s
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .price) {
            price = String(i)
        } else if let d = try? c.decodeIfPresent(Double.self, forKey: .price) {
            price = String(Int(d))
        } else {
            price = nil
        }

        if let i = try? c.decodeIfPresent(Int.self, forKey: .month) {
            month = i
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .month), let i = Int(s) {
            month = i
        } else {
            month = nil
        }
    }
}

// MARK: - Receipt

enum AppStoreReceipt {
    static func base64ReceiptOrRefresh() async throws -> String {
        if let r = try? base64Receipt() {
            return r
        }
        try await AppStore.sync()
        return try base64Receipt()
    }

    static func base64Receipt() throws -> String {
        guard let url = Bundle.main.appStoreReceiptURL else {
            throw TariffPurchaseError.receiptMissing
        }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else {
            throw TariffPurchaseError.receiptMissing
        }
        return data.base64EncodedString()
    }
}

// MARK: - Errors

enum TariffPurchaseError: LocalizedError {
    case productNotFound
    case receiptMissing
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Продукт недоступен в App Store"
        case .receiptMissing:
            return "Не удалось получить чек App Store"
        case .restoreFailed:
            return "Не удалось восстановить покупки"
        }
    }
}
