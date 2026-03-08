import SwiftUI
import WebKit
import Network

struct AntidetectWebView: UIViewRepresentable {
    let profile: BrowserProfile
    let viewModel: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let dataStore = WKWebsiteDataStore(forIdentifier: profile.id)

        if profile.proxy.isValid {
            configureProxy(dataStore: dataStore)
        }

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let spoofJS = FingerprintSpoofEngine.spoofScript(for: profile.fingerprint)
        let spoofScript = WKUserScript(
            source: spoofJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(spoofScript)

        let escapedUA = profile.fingerprint.userAgent.replacingOccurrences(of: "'", with: "\\'")
        let uaScript = WKUserScript(
            source: "Object.defineProperty(navigator,'userAgent',{get:function(){return '\(escapedUA)';},configurable:true});",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(uaScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = profile.fingerprint.userAgent
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        viewModel.webView = webView

        context.coordinator.progressObs = webView.observe(\.estimatedProgress) { view, _ in
            Task { @MainActor in viewModel.estimatedProgress = view.estimatedProgress }
        }
        context.coordinator.titleObs = webView.observe(\.title) { view, _ in
            Task { @MainActor in viewModel.pageTitle = view.title ?? "" }
        }
        context.coordinator.urlObs = webView.observe(\.url) { view, _ in
            Task { @MainActor in
                if let url = view.url {
                    viewModel.urlText = url.absoluteString
                    viewModel.currentURL = url
                }
            }
        }
        context.coordinator.loadingObs = webView.observe(\.isLoading) { view, _ in
            Task { @MainActor in viewModel.isLoading = view.isLoading }
        }
        context.coordinator.backObs = webView.observe(\.canGoBack) { view, _ in
            Task { @MainActor in viewModel.canGoBack = view.canGoBack }
        }
        context.coordinator.forwardObs = webView.observe(\.canGoForward) { view, _ in
            Task { @MainActor in viewModel.canGoForward = view.canGoForward }
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = viewModel.pendingNavigationURL {
            viewModel.pendingNavigationURL = nil
            webView.load(URLRequest(url: url))
        }
    }

    private func configureProxy(dataStore: WKWebsiteDataStore) {
        let proxy = profile.proxy
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(proxy.host),
            port: NWEndpoint.Port(integerLiteral: UInt16(clamping: proxy.port))
        )

        let proxyConfig: ProxyConfiguration
        switch proxy.type {
        case .socks5:
            proxyConfig = ProxyConfiguration(socksv5Proxy: endpoint)
        case .http:
            proxyConfig = ProxyConfiguration(httpCONNECTProxy: endpoint)
        case .none:
            return
        }

        dataStore.proxyConfigurations = [proxyConfig]
    }

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        let viewModel: BrowserViewModel
        weak var webView: WKWebView?
        var progressObs: NSKeyValueObservation?
        var titleObs: NSKeyValueObservation?
        var urlObs: NSKeyValueObservation?
        var loadingObs: NSKeyValueObservation?
        var backObs: NSKeyValueObservation?
        var forwardObs: NSKeyValueObservation?

        init(viewModel: BrowserViewModel) {
            self.viewModel = viewModel
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

        nonisolated func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            decisionHandler(.grant)
        }
    }
}
