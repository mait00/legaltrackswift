//
//  DelaysViewModel.swift
//  LegalTrack
//
//  Ported from legacy RN "Delay" screen.
//

import Foundation

@MainActor
final class DelaysViewModel: ObservableObject {
    @Published private(set) var allDelays: [DelayItem] = []
    @Published private(set) var shownDelays: [DelayItem] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var isTarifActive: Bool?

    @Published var searchText: String = ""

    private let apiService = APIService.shared

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let tariff: TariffsResponse = try await apiService.request(
                endpoint: APIEndpoint.getUserTarif.path,
                method: .get
            )

            let tarifActive = tariff.data?.active ?? false
            isTarifActive = tarifActive

            guard tarifActive else {
                allDelays = []
                shownDelays = []
                isLoading = false
                return
            }

            try await loadDelays()
            isLoading = false
        } catch {
            isLoading = false
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось загрузить задержки"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func refresh() async {
        guard isLoading == false else { return }
        guard isTarifActive != false else { return }
        do {
            try await loadDelays()
        } catch {
            // Refresh should be silent; surface the error only if we have nothing.
            if shownDelays.isEmpty {
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription ?? "Не удалось обновить задержки"
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil

        if query.isEmpty {
            shownDelays = allDelays
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: DelaysResponse = try await apiService.request(
                endpoint: APIEndpoint.searchDelay(query: query).path,
                method: .get
            )
            shownDelays = response.data ?? []
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription ?? "Не удалось выполнить поиск"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadDelays() async throws {
        let response: DelaysResponse = try await apiService.request(
            endpoint: APIEndpoint.getDelays.path,
            method: .get
        )
        let items = response.data ?? []
        allDelays = items

        // If user is searching, don't clobber results; otherwise show full list.
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            shownDelays = items
        }
    }
}

// MARK: - Models

struct DelaysResponse: Codable {
    let message: String?
    let data: [DelayItem]?
}

struct DelayItem: Codable, Identifiable, Hashable {
    let id: Int?
    let datetimeStart: String?
    let datetimeEnd: String?
    let delayUpdate: String?
    let head: String?
    let secondLine: String?
    let delayText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case datetimeStart = "datetime_start"
        case datetimeEnd = "datetime_end"
        case delayUpdate = "delay_update"
        case head
        case secondLine = "second_line"
        case delayText = "delay_text"
    }
}

// MARK: - Formatting Helpers

enum DelayFormatting {
    private static let iso = ISO8601DateFormatter()

    private static let fallbackParsers: [DateFormatter] = {
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US_POSIX")
        df1.timeZone = TimeZone(secondsFromGMT: 0)
        df1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        let df2 = DateFormatter()
        df2.locale = Locale(identifier: "en_US_POSIX")
        df2.timeZone = TimeZone(secondsFromGMT: 0)
        df2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US_POSIX")
        df3.timeZone = TimeZone(secondsFromGMT: 0)
        df3.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return [df1, df2, df3]
    }()

    static func timeString(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if let date = parseDate(raw) {
            return timeFormatter.string(from: date)
        }
        return raw
    }

    static func updatedTimeString(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if let date = parseDate(raw) {
            return timeFormatter.string(from: date)
        }
        return nil
    }

    private static func parseDate(_ raw: String) -> Date? {
        if let d = iso.date(from: raw) {
            return d
        }
        for df in fallbackParsers {
            if let d = df.date(from: raw) {
                return d
            }
        }
        return nil
    }

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.timeZone = .current
        df.dateFormat = "HH:mm"
        return df
    }()
}
