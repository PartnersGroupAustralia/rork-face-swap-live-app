import SwiftUI

struct ProfileEditorView: View {
    let profileManager: ProfileManager
    var existingProfile: BrowserProfile?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🌐"
    @State private var selectedColorHex: String = "007AFF"
    @State private var fingerprintMode: FingerprintMode = .stealthSafari
    @State private var selectedDeviceIndex: Int = 0
    @State private var homeURL: String = ""

    @State private var proxyEnabled: Bool = false
    @State private var proxyType: ProxyType = .socks5
    @State private var proxyHost: String = ""
    @State private var proxyPort: String = "1080"
    @State private var proxyUsername: String = ""
    @State private var proxyPassword: String = ""

    private let colorOptions = [
        "007AFF", "34C759", "FF9500", "FF3B30", "AF52DE",
        "5856D6", "FF2D55", "00C7BE", "FFD60A", "8E8E93"
    ]

    private let emojiOptions = [
        "🌐", "🔒", "🛡️", "👤", "🕵️", "🦊", "🐺",
        "💼", "🎭", "🌑", "⚡", "🔮", "🧊", "🌊"
    ]

    private var isEditing: Bool { existingProfile != nil }

    var body: some View {
        NavigationStack {
            Form {
                profileInfoSection
                fingerprintModeSection
                if fingerprintMode == .stealthSafari {
                    deviceSection
                }
                proxySection
                fingerprintPreviewSection
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var fingerprintModeSection: some View {
        Section {
            Picker("Mode", selection: $fingerprintMode) {
                ForEach(FingerprintMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(fingerprintMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Browser Mode")
        }
    }

    private var profileInfoSection: some View {
        Section("Profile") {
            TextField("Profile Name", text: $name)

            TextField("Home URL (optional)", text: $homeURL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiOptions, id: \.self) { e in
                            Button {
                                emoji = e
                            } label: {
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(emoji == e ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
                                    .clipShape(.rect(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button {
                            selectedColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private var deviceSection: some View {
        Section {
            Picker("Device UA", selection: $selectedDeviceIndex) {
                ForEach(Array(FingerprintConfig.deviceProfiles.enumerated()), id: \.offset) { index, device in
                    Text(device.label).tag(index)
                }
            }

            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            LabeledContent("Platform", value: device.platform)
        } header: {
            Text("User-Agent Identity")
        } footer: {
            Text("Only the User-Agent string is changed (via native API). No JavaScript is injected, so fingerprint.com cannot detect any tampering.")
        }
    }

    private var proxySection: some View {
        Section {
            Toggle("Enable Proxy", isOn: $proxyEnabled)

            if proxyEnabled {
                Picker("Type", selection: $proxyType) {
                    ForEach(ProxyType.allCases.filter { $0 != .none }, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                TextField("Host / IP", text: $proxyHost)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                TextField("Port", text: $proxyPort)
                    .keyboardType(.numberPad)

                TextField("Username (optional)", text: $proxyUsername)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("Password (optional)", text: $proxyPassword)
            }
        } header: {
            Text("Proxy")
        } footer: {
            if proxyEnabled {
                Text("Each profile uses its own isolated proxy connection. SOCKS5 proxies route all traffic including DNS.")
            }
        }
    }

    private var fingerprintPreviewSection: some View {
        Section("Preview") {
            if fingerprintMode == .defaultSafari {
                VStack(alignment: .leading, spacing: 6) {
                    previewRow(label: "Mode", value: "Default Safari")
                    previewRow(label: "Normalization", value: "WKWebView → Safari")
                    previewRow(label: "Tampering", value: "Undetectable")
                    previewRow(label: "Cookies", value: "Isolated per profile")
                    previewRow(label: "Storage", value: "Isolated per profile")
                    if proxyEnabled && !proxyHost.isEmpty {
                        previewRow(label: "Proxy", value: "\(proxyType.displayName) \(proxyHost):\(proxyPort)")
                    }
                }
                .font(.caption)
            } else {
                let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
                VStack(alignment: .leading, spacing: 6) {
                    previewRow(label: "Mode", value: "Stealth (Custom UA)")
                    previewRow(label: "UA", value: String(device.userAgent.prefix(55)) + "...")
                    previewRow(label: "Platform", value: device.platform)
                    previewRow(label: "Normalization", value: "WKWebView → Safari")
                    previewRow(label: "Tampering", value: "Undetectable")
                    if proxyEnabled && !proxyHost.isEmpty {
                        previewRow(label: "Proxy", value: "\(proxyType.displayName) \(proxyHost):\(proxyPort)")
                    }
                }
                .font(.caption)
            }
        }
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 75, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
        }
    }

    private func loadExisting() {
        guard let profile = existingProfile else { return }
        name = profile.name
        emoji = profile.emoji
        selectedColorHex = profile.colorHex
        homeURL = profile.homeURL
        fingerprintMode = profile.fingerprint.mode

        if let idx = FingerprintConfig.deviceProfiles.firstIndex(where: { $0.userAgent == profile.fingerprint.userAgent }) {
            selectedDeviceIndex = idx
        }

        proxyEnabled = profile.proxy.enabled
        proxyType = profile.proxy.type == .none ? .socks5 : profile.proxy.type
        proxyHost = profile.proxy.host
        proxyPort = String(profile.proxy.port)
        proxyUsername = profile.proxy.username
        proxyPassword = profile.proxy.password
    }

    private func saveProfile() {
        let fp: FingerprintConfig

        if fingerprintMode == .defaultSafari {
            fp = .defaultSafari()
        } else {
            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            fp = .stealth(device: device)
        }

        let proxy = ProxyConfig(
            type: proxyEnabled ? proxyType : .none,
            host: proxyHost.trimmingCharacters(in: .whitespaces),
            port: Int(proxyPort) ?? 1080,
            username: proxyUsername,
            password: proxyPassword,
            enabled: proxyEnabled
        )

        if var existing = existingProfile {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.emoji = emoji
            existing.colorHex = selectedColorHex
            existing.homeURL = homeURL.trimmingCharacters(in: .whitespaces)
            existing.fingerprint = fp
            existing.proxy = proxy
            profileManager.updateProfile(existing)
        } else {
            var profile = profileManager.createProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                emoji: emoji,
                colorHex: selectedColorHex,
                fingerprint: fp,
                proxy: proxy
            )
            profile.homeURL = homeURL.trimmingCharacters(in: .whitespaces)
            profileManager.updateProfile(profile)
        }
    }
}
