import SwiftUI
import WebKit
import PhotosUI
import AVKit

struct BrowserFaceSwapView: View {
    @State private var viewModel = BrowserViewModel()
    @FocusState private var isURLBarFocused: Bool
    @State private var videoPickerItem: PhotosPickerItem?
    @State private var imagePickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            progressBar
            browserContent
            bottomToolbar
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $viewModel.showBookmarks) {
            BookmarksSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showOverlayPanel) {
            OverlayControlSheet(viewModel: viewModel)
        }
        .onChange(of: videoPickerItem) { _, item in
            loadVideo(from: item)
        }
        .onChange(of: imagePickerItem) { _, item in
            loadImage(from: item)
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Image(systemName: viewModel.isLoading ? "arrow.clockwise" : "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                TextField("Search or enter URL", text: $viewModel.urlText)
                    .font(.system(size: 15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.webSearch)
                    .focused($isURLBarFocused)
                    .onSubmit {
                        viewModel.navigateTo(viewModel.urlText)
                        isURLBarFocused = false
                    }

                if !viewModel.urlText.isEmpty && isURLBarFocused {
                    Button {
                        viewModel.urlText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(Color(.tertiarySystemFill))
            .clipShape(.rect(cornerRadius: 10))

            if isURLBarFocused {
                Button("Cancel") {
                    isURLBarFocused = false
                    if let url = viewModel.currentURL {
                        viewModel.urlText = url.absoluteString
                    }
                }
                .font(.system(size: 15))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .animation(.spring(duration: 0.25), value: isURLBarFocused)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            if viewModel.isLoading {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * viewModel.estimatedProgress, height: 2)
                    .animation(.linear(duration: 0.2), value: viewModel.estimatedProgress)
            }
        }
        .frame(height: 2)
    }

    private var browserContent: some View {
        ZStack {
            if viewModel.currentURL != nil {
                BrowserWebContainer(viewModel: viewModel)
            } else {
                startPage
            }

            if viewModel.isOverlayActive {
                overlayLayer
            }
        }
    }

    private var startPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(.tertiary)

                    Text("FaceSwapLive Browser")
                        .font(.title2.weight(.semibold))

                    Text("Browse any site with virtual cam overlay")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                if !viewModel.bookmarks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bookmarks")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 72), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.bookmarks.prefix(8)) { bookmark in
                                Button {
                                    viewModel.urlText = bookmark.urlString
                                    viewModel.navigateTo(bookmark.urlString)
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.tertiarySystemFill))
                                                .frame(width: 56, height: 56)

                                            Text(String(bookmark.title.prefix(2)).uppercased())
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(bookmark.displayHost)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 72)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                quickLinks
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                QuickLinkRow(icon: "video.fill", title: "Google Meet", subtitle: "meet.google.com") {
                    viewModel.urlText = "https://meet.google.com"
                    viewModel.navigateTo("https://meet.google.com")
                }
                Divider().padding(.leading, 52)
                QuickLinkRow(icon: "bubble.left.and.bubble.right.fill", title: "Discord", subtitle: "discord.com") {
                    viewModel.urlText = "https://discord.com"
                    viewModel.navigateTo("https://discord.com")
                }
                Divider().padding(.leading, 52)
                QuickLinkRow(icon: "play.rectangle.fill", title: "YouTube", subtitle: "youtube.com") {
                    viewModel.urlText = "https://youtube.com"
                    viewModel.navigateTo("https://youtube.com")
                }
                Divider().padding(.leading, 52)
                QuickLinkRow(icon: "gamecontroller.fill", title: "Twitch", subtitle: "twitch.tv") {
                    viewModel.urlText = "https://twitch.tv"
                    viewModel.navigateTo("https://twitch.tv")
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var overlayLayer: some View {
        Group {
            if let image = viewModel.overlayImage, viewModel.overlayMediaType == .image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(viewModel.overlayOpacity)
                    .allowsHitTesting(false)
            } else if let videoURL = viewModel.overlayVideoURL, viewModel.overlayMediaType == .video {
                LoopingVideoPlayer(url: videoURL)
                    .opacity(viewModel.overlayOpacity)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            Button { viewModel.currentURL = nil } label: {
                toolbarIcon("chevron.backward")
            }
            .disabled(!viewModel.canGoBack && viewModel.currentURL == nil)

            Spacer()

            Button {} label: {
                toolbarIcon("chevron.forward")
            }
            .disabled(!viewModel.canGoForward)

            Spacer()

            Button { viewModel.showOverlayPanel = true } label: {
                Image(systemName: viewModel.isOverlayActive ? "person.crop.rectangle.fill" : "person.crop.rectangle")
                    .font(.system(size: 18))
                    .foregroundStyle(viewModel.isOverlayActive ? Color.accentColor : .primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button {
                viewModel.addBookmark()
            } label: {
                toolbarIcon(viewModel.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
            }
            .disabled(viewModel.currentURL == nil)

            Spacer()

            Button { viewModel.showBookmarks = true } label: {
                toolbarIcon("book")
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(.bar)
    }

    private func toolbarIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
    }

    private func loadVideo(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                viewModel.loadOverlayVideo(movie.url)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.loadOverlayImage(image)
            }
        }
    }
}

nonisolated struct VideoTransferable: Transferable {
    let url: URL

    nonisolated static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempDir = FileManager.default.temporaryDirectory
            let dest = tempDir.appendingPathComponent(UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return VideoTransferable(url: dest)
        }
    }
}

struct BrowserWebContainer: UIViewRepresentable {
    let viewModel: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        context.coordinator.webView = webView

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
        if let url = viewModel.currentURL, webView.url != url {
            webView.load(URLRequest(url: url))
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
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}

    class LoopingPlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        init(url: URL) {
            super.init(frame: .zero)
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            player = queuePlayer

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)
            queuePlayer.play()
            queuePlayer.isMuted = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}

struct QuickLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor, in: .rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct BookmarksSheet: View {
    let viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Pages you bookmark will appear here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.bookmarks) { bookmark in
                            Button {
                                viewModel.urlText = bookmark.urlString
                                viewModel.navigateTo(bookmark.urlString)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.tertiarySystemFill))
                                            .frame(width: 36, height: 36)
                                        Text(String(bookmark.title.prefix(1)).uppercased())
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bookmark.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(bookmark.displayHost)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                viewModel.removeBookmark(viewModel.bookmarks[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct OverlayControlSheet: View {
    let viewModel: BrowserViewModel
    @State private var imagePickerItem: PhotosPickerItem?
    @State private var videoPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.isOverlayActive {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(viewModel.overlayMediaType == .video ? "Video overlay active" : "Image overlay active")
                                .font(.subheadline)
                        }

                        HStack {
                            Text("Opacity")
                                .font(.subheadline)
                            Slider(value: Binding(
                                get: { viewModel.overlayOpacity },
                                set: { viewModel.overlayOpacity = $0 }
                            ), in: 0.1...1.0, step: 0.05)
                        }

                        Button(role: .destructive) {
                            viewModel.clearOverlay()
                            dismiss()
                        } label: {
                            Label("Remove Overlay", systemImage: "trash")
                        }
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("No overlay active")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Virtual Camera Overlay")
                }

                Section {
                    PhotosPicker(selection: $imagePickerItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.fill")
                    }
                    PhotosPicker(selection: $videoPickerItem, matching: .videos) {
                        Label("Choose Video", systemImage: "video.fill")
                    }
                } header: {
                    Text("Upload Media")
                } footer: {
                    Text("Upload a celebrity photo or video to overlay on top of web content. The overlay covers the entire page view.")
                }
            }
            .navigationTitle("Overlay Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: imagePickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.loadOverlayImage(image)
                    dismiss()
                }
            }
        }
        .onChange(of: videoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                    viewModel.loadOverlayVideo(movie.url)
                    dismiss()
                }
            }
        }
    }
}
