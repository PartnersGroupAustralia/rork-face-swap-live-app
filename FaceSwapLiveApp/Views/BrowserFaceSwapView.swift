import SwiftUI

struct BrowserFaceSwapView: View {
    @State private var viewModel = BrowserViewModel()
    @FocusState private var isURLBarFocused: Bool

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
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Image(systemName: viewModel.isLoading ? "arrow.clockwise" : (viewModel.isVirtualCamActive ? "video.fill" : "magnifyingglass"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(viewModel.isVirtualCamActive ? Color.green : .secondary)
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

                    Text("Browse any site with virtual cam injection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                if viewModel.isVirtualCamActive {
                    virtualCamBanner
                }

                if !viewModel.bookmarks.isEmpty {
                    bookmarksGrid
                }

                quickLinks
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var virtualCamBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Virtual Camera Active")
                    .font(.subheadline.weight(.semibold))
                Text(viewModel.virtualCamMode == .replaceAll ? "Replacing all camera feeds" : "Available as selectable device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.1), in: .rect(cornerRadius: 10))
    }

    private var bookmarksGrid: some View {
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

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                quickLinkRow(icon: "camera.viewfinder", title: "Webcam Test", subtitle: "webcamtests.com", url: "https://webcamtests.com/check", tint: .green)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "video.fill", title: "Google Meet", subtitle: "meet.google.com", url: "https://meet.google.com", tint: .blue)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "bubble.left.and.bubble.right.fill", title: "Discord", subtitle: "discord.com", url: "https://discord.com", tint: .indigo)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "play.rectangle.fill", title: "YouTube", subtitle: "youtube.com", url: "https://youtube.com", tint: .red)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "gamecontroller.fill", title: "Twitch", subtitle: "twitch.tv", url: "https://twitch.tv", tint: .purple)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private func quickLinkRow(icon: String, title: String, subtitle: String, url: String, tint: Color = .accentColor) -> some View {
        Button {
            viewModel.urlText = url
            viewModel.navigateTo(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(tint, in: .rect(cornerRadius: 8))

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

    private var overlayLayer: some View {
        Group {
            if let image = viewModel.sourceImage, viewModel.sourceType == .image {
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipped()
                    .opacity(viewModel.overlayOpacity)
            } else if let videoURL = viewModel.sourceVideoURL, viewModel.sourceType == .video {
                LoopingVideoPlayer(url: videoURL)
                    .opacity(viewModel.overlayOpacity)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            Button {
                if viewModel.canGoBack {
                    viewModel.goBack()
                } else {
                    viewModel.goHome()
                }
            } label: {
                toolbarIcon("chevron.backward")
            }
            .disabled(viewModel.currentURL == nil)

            Spacer()

            Button { viewModel.goForward() } label: {
                toolbarIcon("chevron.forward")
            }
            .disabled(!viewModel.canGoForward)

            Spacer()

            Button { viewModel.showOverlayPanel = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: viewModel.isVirtualCamActive ? "web.camera.fill" : "web.camera")
                        .font(.system(size: 18))
                        .foregroundStyle(viewModel.isVirtualCamActive ? Color.green : .primary)
                        .frame(width: 44, height: 44)

                    if viewModel.isVirtualCamActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .offset(x: -6, y: 8)
                    }
                }
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
}
