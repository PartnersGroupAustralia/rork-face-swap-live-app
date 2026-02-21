import SwiftUI
import WebKit
import PhotosUI
import AVFoundation

@Observable
@MainActor
final class BrowserViewModel {
    var urlText: String = ""
    var currentURL: URL?
    var pageTitle: String = ""
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0

    var bookmarks: [Bookmark] = []
    var showBookmarks: Bool = false
    var showOverlayPanel: Bool = false

    var overlayImage: UIImage?
    var overlayVideoURL: URL?
    var overlayMediaType: OverlayMediaType?
    var isOverlayActive: Bool = false
    var overlayOpacity: Double = 1.0

    nonisolated enum OverlayMediaType: Sendable {
        case image
        case video
    }

    private let bookmarksKey = "browser_bookmarks_v1"

    init() {
        loadBookmarks()
    }

    func navigateTo(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url: URL?
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                url = URL(string: trimmed)
            } else {
                url = URL(string: "https://\(trimmed)")
            }
        } else {
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            url = URL(string: "https://www.google.com/search?q=\(query)")
        }

        guard let validURL = url else { return }
        currentURL = validURL
    }

    func addBookmark() {
        guard let url = currentURL else { return }
        let title = pageTitle.isEmpty ? url.host() ?? url.absoluteString : pageTitle
        guard !bookmarks.contains(where: { $0.urlString == url.absoluteString }) else { return }
        let bookmark = Bookmark(title: title, urlString: url.absoluteString)
        bookmarks.insert(bookmark, at: 0)
        saveBookmarks()
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }

    func isCurrentPageBookmarked() -> Bool {
        guard let url = currentURL else { return false }
        return bookmarks.contains { $0.urlString == url.absoluteString }
    }

    func loadOverlayImage(_ image: UIImage) {
        overlayImage = image
        overlayVideoURL = nil
        overlayMediaType = .image
        isOverlayActive = true
    }

    func loadOverlayVideo(_ url: URL) {
        overlayVideoURL = url
        overlayImage = nil
        overlayMediaType = .video
        isOverlayActive = true
    }

    func clearOverlay() {
        overlayImage = nil
        overlayVideoURL = nil
        overlayMediaType = nil
        isOverlayActive = false
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        bookmarks = decoded
    }

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }
}
