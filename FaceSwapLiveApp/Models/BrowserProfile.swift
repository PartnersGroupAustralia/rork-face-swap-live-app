import Foundation

nonisolated struct BrowserProfile: Codable, Identifiable, Sendable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var emoji: String
    var createdAt: Date
    var lastUsed: Date?
    var fingerprint: FingerprintConfig
    var bookmarks: [Bookmark]
    var homeURL: String
    var proxy: ProxyConfig

    init(
        id: UUID = UUID(),
        name: String = "Profile",
        colorHex: String = "007AFF",
        emoji: String = "🌐",
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        fingerprint: FingerprintConfig = .randomized(),
        bookmarks: [Bookmark] = [],
        homeURL: String = "",
        proxy: ProxyConfig = .empty
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.fingerprint = fingerprint
        self.bookmarks = bookmarks
        self.homeURL = homeURL
        self.proxy = proxy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        emoji = try container.decode(String.self, forKey: .emoji)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUsed = try container.decodeIfPresent(Date.self, forKey: .lastUsed)
        fingerprint = try container.decode(FingerprintConfig.self, forKey: .fingerprint)
        bookmarks = try container.decode([Bookmark].self, forKey: .bookmarks)
        homeURL = try container.decode(String.self, forKey: .homeURL)
        proxy = try container.decodeIfPresent(ProxyConfig.self, forKey: .proxy) ?? .empty
    }
}
