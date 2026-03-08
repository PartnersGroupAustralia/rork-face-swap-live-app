import Foundation

nonisolated enum ProxyType: String, Codable, Sendable, CaseIterable {
    case none = "none"
    case socks5 = "socks5"
    case http = "http"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .socks5: return "SOCKS5"
        case .http: return "HTTP"
        }
    }
}

nonisolated struct ProxyConfig: Codable, Sendable, Hashable {
    var type: ProxyType
    var host: String
    var port: Int
    var username: String
    var password: String
    var enabled: Bool

    init(
        type: ProxyType = .none,
        host: String = "",
        port: Int = 1080,
        username: String = "",
        password: String = "",
        enabled: Bool = false
    ) {
        self.type = type
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.enabled = enabled
    }

    static let empty = ProxyConfig()

    var isValid: Bool {
        guard enabled, type != .none else { return false }
        return !host.trimmingCharacters(in: .whitespaces).isEmpty && port > 0 && port <= 65535
    }

    var summary: String {
        guard enabled, type != .none, !host.isEmpty else { return "None" }
        let auth = username.isEmpty ? "" : "\(username)@"
        return "\(type.displayName) \(auth)\(host):\(port)"
    }
}
