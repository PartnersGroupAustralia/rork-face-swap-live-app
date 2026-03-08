import Foundation

nonisolated struct CookieData: Codable, Sendable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let isSecure: Bool
    let isHTTPOnly: Bool
    let expiresDate: Date?
    let sameSitePolicy: String?

    init(
        name: String,
        value: String,
        domain: String,
        path: String,
        isSecure: Bool,
        isHTTPOnly: Bool,
        expiresDate: Date?,
        sameSitePolicy: String?
    ) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.isSecure = isSecure
        self.isHTTPOnly = isHTTPOnly
        self.expiresDate = expiresDate
        self.sameSitePolicy = sameSitePolicy
    }

    static func from(cookie: HTTPCookie) -> CookieData {
        CookieData(
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path,
            isSecure: cookie.isSecure,
            isHTTPOnly: cookie.isHTTPOnly,
            expiresDate: cookie.expiresDate,
            sameSitePolicy: cookie.sameSitePolicy?.rawValue
        )
    }

    var httpCookie: HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .secure: isSecure ? "TRUE" : "FALSE"
        ]
        if let expiresDate {
            properties[.expires] = expiresDate
        }
        if let sameSitePolicy {
            properties[.sameSitePolicy] = sameSitePolicy
        }
        return HTTPCookie(properties: properties)
    }
}

nonisolated struct CookieExport: Codable, Sendable {
    let profileName: String
    let exportDate: Date
    let cookies: [CookieData]
}
