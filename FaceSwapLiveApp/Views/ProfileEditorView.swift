import SwiftUI

struct ProfileEditorView: View {
    let profileManager: ProfileManager
    var existingProfile: BrowserProfile?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🌐"
    @State private var selectedColorHex: String = "007AFF"
    @State private var fingerprintMode: FingerprintMode = .antidetect
    @State private var selectedDeviceIndex: Int = 0
    @State private var selectedTimezoneIndex: Int = 1
    @State private var selectedLanguageIndex: Int = 1
    @State private var blockWebRTC: Bool = true
    @State private var spoofFonts: Bool = true
    @State private var homeURL: String = ""

    @State private var proxyEnabled: Bool = false
    @State private var proxyType: ProxyType = .socks5
    @State private var proxyHost: String = ""
    @State private var proxyPort: String = "1080"
    @State private var proxyUsername: String = ""
    @State private var proxyPassword: String = ""

    @State private var isDetectingIP: Bool = false
    @State private var detectedInfo: String?
    @State private var autoTimezone: Bool = false
    @State private var autoLanguage: Bool = false

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
                if fingerprintMode == .antidetect {
                    deviceSection
                    locationSection
                }
                proxySection
                if fingerprintMode == .antidetect {
                    privacySection
                }
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
            Text("Fingerprint Mode")
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
        Section("Device Fingerprint") {
            Picker("Device", selection: $selectedDeviceIndex) {
                ForEach(Array(FingerprintConfig.deviceProfiles.enumerated()), id: \.offset) { index, device in
                    Text(device.label).tag(index)
                }
            }

            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            LabeledContent("Screen", value: "\(device.screenWidth)x\(device.screenHeight)")
            LabeledContent("Cores", value: "\(device.hardwareConcurrency)")
            LabeledContent("Memory", value: "\(device.deviceMemory) GB")
            LabeledContent("Touch", value: device.maxTouchPoints > 0 ? "Yes" : "No")
        }
    }

    private var locationSection: some View {
        Section {
            Button {
                detectFromIP()
            } label: {
                HStack {
                    Label("Auto-Detect from IP", systemImage: "location.circle")
                    Spacer()
                    if isDetectingIP {
                        ProgressView()
                    }
                }
            }
            .disabled(isDetectingIP)

            if let info = detectedInfo {
                Text(info)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Picker("Timezone", selection: $selectedTimezoneIndex) {
                ForEach(Array(FingerprintConfig.timezones.enumerated()), id: \.offset) { index, tz in
                    Text(tz.label).tag(index)
                }
            }

            Picker("Language", selection: $selectedLanguageIndex) {
                ForEach(Array(FingerprintConfig.languageSets.enumerated()), id: \.offset) { index, lang in
                    Text(lang.label).tag(index)
                }
            }
        } header: {
            Text("Location & Language")
        } footer: {
            Text("\"Auto (Based on IP)\" will detect timezone and language when the profile launches, matching them to your current IP or proxy IP.")
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

    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Block WebRTC Leaks", isOn: $blockWebRTC)
            Toggle("Spoof Font List", isOn: $spoofFonts)
        }
    }

    private var fingerprintPreviewSection: some View {
        Section("Fingerprint Preview") {
            if fingerprintMode == .defaultSafari {
                VStack(alignment: .leading, spacing: 6) {
                    previewRow(label: "Mode", value: "Native Safari")
                    previewRow(label: "Spoofing", value: "None")
                    previewRow(label: "Cookies", value: "Isolated per profile")
                    previewRow(label: "Storage", value: "Isolated per profile")
                    if proxyEnabled && !proxyHost.isEmpty {
                        previewRow(label: "Proxy", value: "\(proxyType.displayName) \(proxyHost):\(proxyPort)")
                    }
                }
                .font(.caption)
            } else {
            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            let tzIndex = selectedTimezoneIndex
            let langIndex = selectedLanguageIndex

            VStack(alignment: .leading, spacing: 6) {
                previewRow(label: "UA", value: String(device.userAgent.prefix(60)) + "...")
                previewRow(label: "Platform", value: device.platform)
                previewRow(label: "Screen", value: "\(device.screenWidth)x\(device.screenHeight) @\(device.pixelRatio)x")
                if tzIndex == 0 {
                    previewRow(label: "Timezone", value: "Auto (Based on IP)")
                } else {
                    previewRow(label: "Timezone", value: FingerprintConfig.timezones[tzIndex].zone)
                }
                if langIndex == 0 {
                    previewRow(label: "Language", value: "Auto (Based on IP)")
                } else {
                    previewRow(label: "Language", value: FingerprintConfig.languageSets[langIndex].langs.joined(separator: ", "))
                }
                previewRow(label: "WebRTC", value: blockWebRTC ? "Blocked" : "Allowed")
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
                .frame(width: 60, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
        }
    }

    private func detectFromIP() {
        isDetectingIP = true
        detectedInfo = nil
        Task {
            guard let result = await IPGeolocationService.detect() else {
                isDetectingIP = false
                detectedInfo = "Detection failed. Check your connection."
                return
            }

            if let tzIdx = FingerprintConfig.timezones.firstIndex(where: { $0.zone == result.timezone }) {
                selectedTimezoneIndex = tzIdx
            }

            if let langIdx = FingerprintConfig.languageSets.firstIndex(where: {
                guard let first = $0.langs.first else { return false }
                return first.hasPrefix(result.countryCode.lowercased()) || $0.langs == result.languages
            }) {
                selectedLanguageIndex = langIdx
            } else {
                let matchingLangs = FingerprintConfig.countryToLanguage[result.countryCode]
                if let langs = matchingLangs,
                   let idx = FingerprintConfig.languageSets.firstIndex(where: { $0.langs == langs }) {
                    selectedLanguageIndex = idx
                }
            }

            let ip = result.ip.isEmpty ? "" : " (\(result.ip))"
            detectedInfo = "Detected: \(result.timezone), \(result.countryCode)\(ip)"
            isDetectingIP = false
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
        if profile.fingerprint.autoDetectFromIP {
            selectedTimezoneIndex = 0
            selectedLanguageIndex = 0
        } else {
            if let idx = FingerprintConfig.timezones.firstIndex(where: { $0.zone == profile.fingerprint.timezone }) {
                selectedTimezoneIndex = idx
            }
            if let idx = FingerprintConfig.languageSets.firstIndex(where: { $0.langs == profile.fingerprint.languages }) {
                selectedLanguageIndex = idx
            }
        }
        blockWebRTC = profile.fingerprint.blockWebRTC
        spoofFonts = profile.fingerprint.spoofFonts

        proxyEnabled = profile.proxy.enabled
        proxyType = profile.proxy.type == .none ? .socks5 : profile.proxy.type
        proxyHost = profile.proxy.host
        proxyPort = String(profile.proxy.port)
        proxyUsername = profile.proxy.username
        proxyPassword = profile.proxy.password
    }

    private func saveProfile() {
        var fp: FingerprintConfig

        if fingerprintMode == .defaultSafari {
            fp = .defaultSafari()
        } else {
            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            let isAutoTZ = selectedTimezoneIndex == 0
            let isAutoLang = selectedLanguageIndex == 0

            let tz = isAutoTZ ? FingerprintConfig.timezones[2] : FingerprintConfig.timezones[selectedTimezoneIndex]
            let lang = isAutoLang ? FingerprintConfig.languageSets[1] : FingerprintConfig.languageSets[selectedLanguageIndex]

            fp = FingerprintConfig.from(device: device)
            fp.timezone = tz.zone
            fp.timezoneOffset = tz.offset
            fp.languages = lang.langs
            fp.blockWebRTC = blockWebRTC
            fp.spoofFonts = spoofFonts
            fp.autoDetectFromIP = isAutoTZ || isAutoLang
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
            fp.canvasSeed = existing.fingerprint.canvasSeed
            fp.audioSeed = existing.fingerprint.audioSeed
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
