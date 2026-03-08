import Foundation

struct Bookmark: Codable, Identifiable, Sendable, Hashable {
    nonisolated var id: UUID
    nonisolated var title: String
    nonisolated var urlString: String
    nonisolated var dateAdded: Date

    nonisolated init(id: UUID = UUID(), title: String, urlString: String, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.dateAdded = dateAdded
    }

    nonisolated var url: URL? { URL(string: urlString) }
    nonisolated var displayHost: String { url?.host() ?? urlString }
}
