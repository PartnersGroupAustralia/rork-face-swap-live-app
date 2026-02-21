import SwiftUI
import WebKit

struct BrowserWebContainer: UIViewRepresentable {
    let viewModel: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        config.setURLSchemeHandler(viewModel.schemeHandler, forURLScheme: "fslvideo")

        let vcamScript = WKUserScript(
            source: VirtualCamJSProvider.patchScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(vcamScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        context.coordinator.webView = webView
        viewModel.webView = webView

        context.coordinator.progressObservation = webView.observe(\.estimatedProgress) { view, _ in
            Task { @MainActor in
                viewModel.estimatedProgress = view.estimatedProgress
            }
        }
        context.coordinator.titleObservation = webView.observe(\.title) { view, _ in
            Task { @MainActor in
                viewModel.pageTitle = view.title ?? ""
            }
        }
        context.coordinator.urlObservation = webView.observe(\.url) { view, _ in
            Task { @MainActor in
                if let url = view.url {
                    viewModel.urlText = url.absoluteString
                    viewModel.currentURL = url
                }
            }
        }
        context.coordinator.loadingObservation = webView.observe(\.isLoading) { view, _ in
            Task { @MainActor in
                viewModel.isLoading = view.isLoading
            }
        }
        context.coordinator.canGoBackObservation = webView.observe(\.canGoBack) { view, _ in
            Task { @MainActor in
                viewModel.canGoBack = view.canGoBack
            }
        }
        context.coordinator.canGoForwardObservation = webView.observe(\.canGoForward) { view, _ in
            Task { @MainActor in
                viewModel.canGoForward = view.canGoForward
            }
        }

        if let url = viewModel.currentURL {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let targetURL = viewModel.currentURL else { return }
        if webView.url != targetURL {
            webView.load(URLRequest(url: targetURL))
        }
    }

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        let viewModel: BrowserViewModel
        weak var webView: WKWebView?
        var progressObservation: NSKeyValueObservation?
        var titleObservation: NSKeyValueObservation?
        var urlObservation: NSKeyValueObservation?
        var loadingObservation: NSKeyValueObservation?
        var canGoBackObservation: NSKeyValueObservation?
        var canGoForwardObservation: NSKeyValueObservation?

        init(viewModel: BrowserViewModel) {
            self.viewModel = viewModel
        }

        nonisolated func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            decisionHandler(.grant)
        }

        nonisolated func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        nonisolated func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == false {
                webView.load(navigationAction.request)
            }
            return nil
        }

        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.syncVirtualCamToPage()
            }
        }
    }
}
