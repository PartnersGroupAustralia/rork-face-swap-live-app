import SwiftUI
import WebKit

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
    var pendingNavigationURL: URL?
    var showBookmarks: Bool = false

    weak var webView: WKWebView?

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
        pendingNavigationURL = validURL
        currentURL = validURL
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func goHome() {
        currentURL = nil
        urlText = ""
        webView = nil
    }
}
