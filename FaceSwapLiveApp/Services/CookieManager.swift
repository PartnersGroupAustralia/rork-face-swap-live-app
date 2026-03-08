import Foundation
import WebKit

enum CookieManager {
    static func exportCookies(for profileID: UUID, profileName: String) async -> Data? {
        let dataStore = WKWebsiteDataStore(forIdentifier: profileID)
        let cookies = await dataStore.httpCookieStore.allCookies()
        let cookieDataArray = cookies.map { CookieData.from(cookie: $0) }
        let export = CookieExport(
            profileName: profileName,
            exportDate: Date(),
            cookies: cookieDataArray
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(export)
    }

    static func importCookies(data: Data, to profileID: UUID) async -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let cookieExport = try? decoder.decode(CookieExport.self, from: data) else { return 0 }
        let dataStore = WKWebsiteDataStore(forIdentifier: profileID)
        var count = 0
        for cookieData in cookieExport.cookies {
            if let cookie = cookieData.httpCookie {
                await dataStore.httpCookieStore.setCookie(cookie)
                count += 1
            }
        }
        return count
    }

    static func clearCookies(for profileID: UUID) async {
        let dataStore = WKWebsiteDataStore(forIdentifier: profileID)
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let records = await dataStore.dataRecords(ofTypes: allTypes)
        if !records.isEmpty {
            await dataStore.removeData(ofTypes: allTypes, for: records)
        }
    }

    static func cookieCount(for profileID: UUID) async -> Int {
        let dataStore = WKWebsiteDataStore(forIdentifier: profileID)
        let cookies = await dataStore.httpCookieStore.allCookies()
        return cookies.count
    }
}
