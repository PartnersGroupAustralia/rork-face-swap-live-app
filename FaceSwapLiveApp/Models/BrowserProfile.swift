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

    init(
        id: UUID = UUID(),
        name: String = "Profile",
        colorHex: String = "007AFF",
        emoji: String = "🌐",
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        fingerprint: FingerprintConfig = .randomized(),
        bookmarks: [Bookmark] = [],
        homeURL: String = ""
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
    }
}
