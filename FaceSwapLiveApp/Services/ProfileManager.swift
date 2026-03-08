import Foundation
import WebKit

@Observable
final class ProfileManager {
    var profiles: [BrowserProfile] = []

    private let storageKey = "antidetect_profiles_v1"

    init() {
        loadProfiles()
    }

    func createProfile(name: String, emoji: String, colorHex: String, fingerprint: FingerprintConfig) -> BrowserProfile {
        let profile = BrowserProfile(
            name: name,
            colorHex: colorHex,
            emoji: emoji,
            fingerprint: fingerprint
        )
        profiles.insert(profile, at: 0)
        saveProfiles()
        return profile
    }

    func updateProfile(_ profile: BrowserProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveProfiles()
    }

    func deleteProfile(_ profile: BrowserProfile) {
        let profileID = profile.id
        profiles.removeAll { $0.id == profileID }
        saveProfiles()
        Task {
            try? await WKWebsiteDataStore.remove(forIdentifier: profileID)
        }
    }

    func markUsed(_ profile: BrowserProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index].lastUsed = Date()
        saveProfiles()
    }

    func addBookmark(to profileID: UUID, bookmark: Bookmark) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        guard !profiles[index].bookmarks.contains(where: { $0.urlString == bookmark.urlString }) else { return }
        profiles[index].bookmarks.insert(bookmark, at: 0)
        saveProfiles()
    }

    func removeBookmark(from profileID: UUID, bookmark: Bookmark) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[index].bookmarks.removeAll { $0.id == bookmark.id }
        saveProfiles()
    }

    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BrowserProfile].self, from: data) else { return }
        profiles = decoded
    }

    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
