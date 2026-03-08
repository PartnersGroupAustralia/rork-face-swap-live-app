import SwiftUI

struct ProfileEditorView: View {
    let profileManager: ProfileManager
    var existingProfile: BrowserProfile?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "🌐"
    @State private var selectedColorHex: String = "007AFF"
    @State private var selectedDeviceIndex: Int = 0
    @State private var selectedTimezoneIndex: Int = 0
    @State private var selectedLanguageIndex: Int = 0
    @State private var blockWebRTC: Bool = true
    @State private var spoofFonts: Bool = true

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
                deviceSection
                locationSection
                privacySection
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

    private var profileInfoSection: some View {
        Section("Profile") {
            TextField("Profile Name", text: $name)

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
            LabeledContent("Screen", value: "\(device.screenWidth)×\(device.screenHeight)")
            LabeledContent("Cores", value: "\(device.hardwareConcurrency)")
            LabeledContent("Memory", value: "\(device.deviceMemory) GB")
            LabeledContent("Touch", value: device.maxTouchPoints > 0 ? "Yes" : "No")
        }
    }

    private var locationSection: some View {
        Section("Location & Language") {
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
            let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
            let tz = FingerprintConfig.timezones[selectedTimezoneIndex]
            let lang = FingerprintConfig.languageSets[selectedLanguageIndex]

            VStack(alignment: .leading, spacing: 6) {
                previewRow(label: "UA", value: String(device.userAgent.prefix(60)) + "...")
                previewRow(label: "Platform", value: device.platform)
                previewRow(label: "Screen", value: "\(device.screenWidth)×\(device.screenHeight) @\(device.pixelRatio)x")
                previewRow(label: "Timezone", value: tz.zone)
                previewRow(label: "Language", value: lang.langs.joined(separator: ", "))
                previewRow(label: "WebRTC", value: blockWebRTC ? "Blocked" : "Allowed")
            }
            .font(.caption)
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

    private func loadExisting() {
        guard let profile = existingProfile else { return }
        name = profile.name
        emoji = profile.emoji
        selectedColorHex = profile.colorHex

        if let idx = FingerprintConfig.deviceProfiles.firstIndex(where: { $0.userAgent == profile.fingerprint.userAgent }) {
            selectedDeviceIndex = idx
        }
        if let idx = FingerprintConfig.timezones.firstIndex(where: { $0.zone == profile.fingerprint.timezone }) {
            selectedTimezoneIndex = idx
        }
        if let idx = FingerprintConfig.languageSets.firstIndex(where: { $0.langs == profile.fingerprint.languages }) {
            selectedLanguageIndex = idx
        }
        blockWebRTC = profile.fingerprint.blockWebRTC
        spoofFonts = profile.fingerprint.spoofFonts
    }

    private func saveProfile() {
        let device = FingerprintConfig.deviceProfiles[selectedDeviceIndex]
        let tz = FingerprintConfig.timezones[selectedTimezoneIndex]
        let lang = FingerprintConfig.languageSets[selectedLanguageIndex]

        var fp = FingerprintConfig.from(device: device)
        fp.timezone = tz.zone
        fp.timezoneOffset = tz.offset
        fp.languages = lang.langs
        fp.blockWebRTC = blockWebRTC
        fp.spoofFonts = spoofFonts

        if var existing = existingProfile {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.emoji = emoji
            existing.colorHex = selectedColorHex
            fp.canvasSeed = existing.fingerprint.canvasSeed
            fp.audioSeed = existing.fingerprint.audioSeed
            existing.fingerprint = fp
            profileManager.updateProfile(existing)
        } else {
            _ = profileManager.createProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                emoji: emoji,
                colorHex: selectedColorHex,
                fingerprint: fp
            )
        }
    }
}
