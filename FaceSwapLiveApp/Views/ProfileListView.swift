import SwiftUI

struct ProfileListView: View {
    @State private var profileManager = ProfileManager()
    @State private var showCreateProfile: Bool = false
    @State private var activeProfile: BrowserProfile?
    @State private var profileToEdit: BrowserProfile?
    @State private var profileToDelete: BrowserProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCard(profile: profile) {
                            profileManager.markUsed(profile)
                            activeProfile = profile
                        } onEdit: {
                            profileToEdit = profile
                        } onDelete: {
                            profileToDelete = profile
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if profileManager.profiles.isEmpty {
                    emptyState
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateProfile = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateProfile) {
                ProfileEditorView(profileManager: profileManager)
            }
            .sheet(item: $profileToEdit) { profile in
                ProfileEditorView(profileManager: profileManager, existingProfile: profile)
            }
            .fullScreenCover(item: $activeProfile) { profile in
                BrowserView(profile: profile, profileManager: profileManager)
            }
            .alert("Delete Profile?", isPresented: Binding(
                get: { profileToDelete != nil },
                set: { if !$0 { profileToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { profileToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let p = profileToDelete {
                        profileManager.deleteProfile(p)
                        profileToDelete = nil
                    }
                }
            } message: {
                Text("This will permanently delete the profile and all its browsing data, cookies, and history.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.tertiary)
                .padding(.top, 80)

            Text("No Profiles Yet")
                .font(.title2.weight(.semibold))

            Text("Each profile has its own cookies, storage, proxy, and unique browser fingerprint. Create one to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showCreateProfile = true
            } label: {
                Label("Create Profile", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }
}

struct ProfileCard: View {
    let profile: BrowserProfile
    let onLaunch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onLaunch) {
            HStack(spacing: 14) {
                Text(profile.emoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: profile.colorHex).opacity(0.15))
                    .clipShape(.rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(fingerprintSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if profile.proxy.isValid {
                        HStack(spacing: 4) {
                            Image(systemName: "network")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text(profile.proxy.summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let lastUsed = profile.lastUsed {
                        Text("Last used \(lastUsed.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
        .contextMenu {
            Button { onLaunch() } label: {
                Label("Open", systemImage: "globe")
            }
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var fingerprintSummary: String {
        let fp = profile.fingerprint
        let device: String
        if fp.platform.contains("iPhone") { device = "iPhone" }
        else if fp.platform.contains("iPad") { device = "iPad" }
        else if fp.platform == "MacIntel" { device = "Mac" }
        else if fp.platform == "Win32" { device = "Windows" }
        else { device = "Android" }
        return "\(device) · \(fp.timezone.split(separator: "/").last ?? Substring(fp.timezone))"
    }
}
