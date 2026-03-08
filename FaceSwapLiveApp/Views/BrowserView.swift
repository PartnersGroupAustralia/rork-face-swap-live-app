import SwiftUI
import UniformTypeIdentifiers

struct BrowserView: View {
    let profile: BrowserProfile
    let profileManager: ProfileManager
    @State private var viewModel = BrowserViewModel()
    @FocusState private var isURLBarFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showCookieSheet: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var cookieCount: Int = 0
    @State private var importMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isFullScreen {
                headerBar
                progressBar
            }
            browserContent
            if !viewModel.isFullScreen {
                bottomToolbar
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            if viewModel.isFullScreen {
                fullScreenOverlay
            }
        }
        .sheet(isPresented: $viewModel.showBookmarks) {
            BookmarksSheet(profile: profile, profileManager: profileManager, viewModel: viewModel)
        }
        .sheet(isPresented: $showCookieSheet) {
            CookieManagerSheet(
                profile: profile,
                viewModel: viewModel,
                cookieCount: $cookieCount,
                onImport: { showImportPicker = true },
                onExport: { exportCookies() }
            )
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let data = viewModel.exportedCookieData {
                CookieShareSheet(data: data, profileName: profile.name)
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Cookies Imported", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK") { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
        .onAppear {
            if !profile.homeURL.isEmpty, URL(string: profile.homeURL) != nil {
                viewModel.urlText = profile.homeURL
                viewModel.navigateTo(profile.homeURL)
            }
            Task { cookieCount = await CookieManager.cookieCount(for: profile.id) }
        }
        .statusBarHidden(viewModel.isFullScreen)
    }

    private var fullScreenOverlay: some View {
        HStack {
            Spacer()
            Button {
                viewModel.toggleFullScreen()
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.5), in: Circle())
            }
            .padding(.trailing, 12)
            .padding(.top, 4)
        }
        .transition(.opacity)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }

            HStack(spacing: 0) {
                Image(systemName: statusIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                TextField("Search or enter URL", text: $viewModel.urlText)
                    .font(.system(size: 14))
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
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 8)
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
                .font(.system(size: 14))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
        .animation(.spring(duration: 0.25), value: isURLBarFocused)
    }

    private var statusIcon: String {
        if viewModel.isLoading { return "arrow.clockwise" }
        if viewModel.currentURL?.scheme == "https" { return "lock.fill" }
        return "magnifyingglass"
    }

    private var statusColor: Color {
        if viewModel.currentURL?.scheme == "https" { return .green }
        return .secondary
    }

    private var progressBar: some View {
        GeometryReader { geo in
            if viewModel.isLoading {
                Rectangle()
                    .fill(Color(hex: profile.colorHex))
                    .frame(width: geo.size.width * viewModel.estimatedProgress, height: 2)
                    .animation(.linear(duration: 0.2), value: viewModel.estimatedProgress)
            }
        }
        .frame(height: 2)
    }

    private var browserContent: some View {
        Group {
            if viewModel.currentURL != nil {
                AntidetectWebView(profile: profile, viewModel: viewModel)
            } else {
                startPage
            }
        }
    }

    private var startPage: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text(profile.emoji)
                        .font(.system(size: 48))

                    Text(profile.name)
                        .font(.title2.weight(.semibold))

                    HStack(spacing: 6) {
                        Image(systemName: profile.fingerprint.mode == .defaultSafari ? "safari" : "checkmark.shield.fill")
                            .foregroundStyle(profile.fingerprint.mode == .defaultSafari ? .blue : .green)
                        Text(profile.fingerprint.mode == .defaultSafari ? "Default Safari" : "Stealth (Custom UA)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    if profile.proxy.isValid {
                        HStack(spacing: 6) {
                            Image(systemName: "network")
                                .foregroundStyle(.blue)
                            Text(profile.proxy.summary)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 48)

                fingerprintSummaryCard

                if !profile.bookmarks.isEmpty {
                    bookmarksGrid
                }

                quickLinks
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var fingerprintSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(profile.fingerprint.mode == .defaultSafari ? "Default Safari" : "Stealth Mode", systemImage: profile.fingerprint.mode == .defaultSafari ? "safari" : "checkmark.shield")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let fp = profile.fingerprint
            VStack(spacing: 0) {
                if fp.mode == .defaultSafari {
                    infoRow(icon: "checkmark.circle", label: "Mode", value: "Default Safari")
                    Divider().padding(.leading, 36)
                    infoRow(icon: "hand.raised", label: "Tampering", value: "None")
                    Divider().padding(.leading, 36)
                    infoRow(icon: "cylinder.split.1x2", label: "Cookies", value: "Isolated")
                    Divider().padding(.leading, 36)
                    infoRow(icon: "externaldrive", label: "Storage", value: "Isolated")
                } else {
                    infoRow(icon: "checkmark.shield", label: "Mode", value: "Stealth")
                    Divider().padding(.leading, 36)
                    infoRow(icon: "desktopcomputer", label: "UA Device", value: fp.deviceLabel.isEmpty ? fp.platform : fp.deviceLabel)
                    Divider().padding(.leading, 36)
                    infoRow(icon: "hand.raised", label: "Tampering", value: "None")
                    Divider().padding(.leading, 36)
                    infoRow(icon: "cylinder.split.1x2", label: "Cookies", value: "Isolated")
                }
                Divider().padding(.leading, 36)
                infoRow(icon: "network", label: "Proxy", value: profile.proxy.isValid ? profile.proxy.summary : "None")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 10))
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var bookmarksGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bookmarks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 72), spacing: 16)
            ], spacing: 16) {
                ForEach(profile.bookmarks.prefix(8)) { bookmark in
                    Button {
                        viewModel.urlText = bookmark.urlString
                        viewModel.navigateTo(bookmark.urlString)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 52, height: 52)
                                Text(String(bookmark.title.prefix(2)).uppercased())
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
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
        }
    }

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Links")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                quickLinkRow(icon: "hand.raised.fill", title: "Fingerprint Test", subtitle: "fingerprint.com/demo", url: "https://fingerprint.com/demo", tint: .orange)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "shield.fill", title: "BrowserLeaks", subtitle: "browserleaks.com", url: "https://browserleaks.com", tint: .green)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "network", title: "AmIUnique", subtitle: "amiunique.org", url: "https://amiunique.org", tint: .indigo)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "shield.lefthalf.filled", title: "CreepJS", subtitle: "abrahamjuliot.github.io/creepjs", url: "https://abrahamjuliot.github.io/creepjs/", tint: .purple)
                Divider().padding(.leading, 52)
                quickLinkRow(icon: "magnifyingglass", title: "Google", subtitle: "google.com", url: "https://google.com", tint: .blue)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private func quickLinkRow(icon: String, title: String, subtitle: String, url: String, tint: Color) -> some View {
        Button {
            viewModel.urlText = url
            viewModel.navigateTo(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint, in: .rect(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 1) {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
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

            Button { viewModel.reload() } label: {
                toolbarIcon("arrow.clockwise")
            }
            .disabled(viewModel.currentURL == nil)

            Spacer()

            Button { viewModel.toggleFullScreen() } label: {
                toolbarIcon("arrow.up.left.and.arrow.down.right")
            }
            .disabled(viewModel.currentURL == nil)

            Spacer()

            Menu {
                Button { addBookmark() } label: {
                    let isBookmarked = profile.bookmarks.contains { $0.urlString == viewModel.currentURL?.absoluteString }
                    Label(isBookmarked ? "Bookmarked" : "Add Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .disabled(viewModel.currentURL == nil)

                Button { viewModel.showBookmarks = true } label: {
                    Label("All Bookmarks", systemImage: "book")
                }

                Divider()

                Button { showCookieSheet = true } label: {
                    Label("Cookie Manager", systemImage: "cylinder.split.1x2")
                }
            } label: {
                toolbarIcon("ellipsis")
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(.bar)
    }

    private func toolbarIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
    }

    private func addBookmark() {
        guard let url = viewModel.currentURL else { return }
        let title = viewModel.pageTitle.isEmpty ? url.host() ?? url.absoluteString : viewModel.pageTitle
        let bookmark = Bookmark(title: title, urlString: url.absoluteString)
        profileManager.addBookmark(to: profile.id, bookmark: bookmark)
    }

    private func exportCookies() {
        Task {
            guard let data = await CookieManager.exportCookies(for: profile.id, profileName: profile.name) else { return }
            viewModel.exportedCookieData = data
            showCookieSheet = false
            viewModel.showShareSheet = true
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        Task {
            let count = await CookieManager.importCookies(data: data, to: profile.id)
            importMessage = "Successfully imported \(count) cookies."
            cookieCount = await CookieManager.cookieCount(for: profile.id)
        }
    }
}
