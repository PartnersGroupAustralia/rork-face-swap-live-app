import Foundation

struct BrowserProfile: Codable, Identifiable, Sendable, Hashable {
    nonisolated var id: UUID
    nonisolated var name: String
    nonisolated var colorHex: String
    nonisolated var emoji: String
    nonisolated var createdAt: Date
    nonisolated var lastUsed: Date?
    nonisolated var fingerprint: FingerprintConfig
    nonisolated var bookmarks: [Bookmark]
    nonisolated var homeURL: String

    nonisolated init(
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
