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

    var bookmarks: [Bookmark] = []
    var showBookmarks: Bool = false
    var showOverlayPanel: Bool = false

    var sourceImage: UIImage?
    var sourceVideoURL: URL?
    var sourceType: SourceMediaType?

    var isVirtualCamActive: Bool = false
    var virtualCamMode: VirtualCamMode = .replaceAll

    var isOverlayActive: Bool = false
    var overlayOpacity: Double = 1.0

    weak var webView: WKWebView?
    let schemeHandler = VirtualCamSchemeHandler()

    var hasSource: Bool { sourceType != nil }

    nonisolated enum SourceMediaType: Sendable {
        case image
        case video
    }

    nonisolated enum VirtualCamMode: Sendable, CaseIterable, Identifiable {
        case replaceAll
        case addDevice

        nonisolated var id: Self { self }

        nonisolated var label: String {
            switch self {
            case .replaceAll: "Replace All Cameras"
            case .addDevice: "Add as Selectable Device"
            }
        }
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

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func goHome() {
        currentURL = nil
        urlText = ""
        webView = nil
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

    func loadSource(image: UIImage) {
        sourceImage = image
        sourceVideoURL = nil
        sourceType = .image
        schemeHandler.videoFileURL = nil
        if isVirtualCamActive { syncVirtualCamToPage() }
        if isOverlayActive { }
    }

    func loadSource(videoURL: URL) {
        sourceVideoURL = videoURL
        sourceImage = nil
        sourceType = .video
        schemeHandler.videoFileURL = videoURL
        if isVirtualCamActive { syncVirtualCamToPage() }
    }

    func clearSource() {
        sourceImage = nil
        sourceVideoURL = nil
        sourceType = nil
        isVirtualCamActive = false
        isOverlayActive = false
        schemeHandler.videoFileURL = nil
        syncVirtualCamToPage()
    }

    func setVirtualCam(active: Bool) {
        guard hasSource || !active else { return }
        isVirtualCamActive = active
        updateUserScripts()
        syncVirtualCamToPage()
    }

    func updateUserScripts() {
        guard let webView else { return }
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()

        controller.addUserScript(WKUserScript(
            source: VirtualCamJSProvider.patchScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))

        if isVirtualCamActive, hasSource {
            let stateJS = buildStateJS()
            controller.addUserScript(WKUserScript(
                source: stateJS,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            ))
        }
    }

    func syncVirtualCamToPage() {
        guard let webView else { return }

        if !isVirtualCamActive || !hasSource {
            webView.evaluateJavaScript(
                "if(window.__fslVCam){window.__fslVCam.active=false;}try{navigator.mediaDevices.dispatchEvent(new Event('devicechange'));}catch(e){}",
                completionHandler: nil
            )
            return
        }

        let js = buildStateJS()
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func buildStateJS() -> String {
        let replaceAll = virtualCamMode == .replaceAll

        if let image = sourceImage, let data = image.jpegData(compressionQuality: 0.8) {
            let b64 = data.base64EncodedString()
            return """
            (function(){
            if(!window.__fslVCam)return;
            window.__fslVCam.active=true;
            window.__fslVCam.replaceAll=\(replaceAll);
            window.__fslVCam.imageSrc='data:image/jpeg;base64,\(b64)';
            window.__fslVCam.videoSrc=null;
            try{navigator.mediaDevices.dispatchEvent(new Event('devicechange'));}catch(e){}
            })();
            """
        } else if sourceVideoURL != nil {
            return """
            (function(){
            if(!window.__fslVCam)return;
            window.__fslVCam.active=true;
            window.__fslVCam.replaceAll=\(replaceAll);
            window.__fslVCam.videoSrc='fslvideo://media';
            window.__fslVCam.imageSrc=null;
            try{navigator.mediaDevices.dispatchEvent(new Event('devicechange'));}catch(e){}
            })();
            """
        }

        return "if(window.__fslVCam){window.__fslVCam.active=false;}"
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
