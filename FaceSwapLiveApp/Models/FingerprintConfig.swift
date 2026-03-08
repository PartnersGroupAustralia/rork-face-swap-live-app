import Foundation

nonisolated enum FingerprintMode: String, Codable, Sendable, Hashable, CaseIterable {
    case defaultSafari = "default"
    case stealthSafari = "stealth"

    var displayName: String {
        switch self {
        case .defaultSafari: return "Default Safari"
        case .stealthSafari: return "Stealth (Custom UA)"
        }
    }

    var description: String {
        switch self {
        case .defaultSafari: return "Pure native Safari. No modifications at all. Isolated cookies, storage, and proxy only. Guaranteed 0 suspect score."
        case .stealthSafari: return "Sets a custom User-Agent via native API (undetectable). Isolated cookies, storage, and proxy. No JavaScript injection — 0 suspect score."
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "default": self = .defaultSafari
        case "stealth": self = .stealthSafari
        case "antidetect": self = .stealthSafari
        default: self = .defaultSafari
        }
    }
}

nonisolated struct FingerprintConfig: Codable, Sendable, Hashable {
    var mode: FingerprintMode
    var userAgent: String
    var platform: String
    var deviceLabel: String

    init(
        mode: FingerprintMode = .stealthSafari,
        userAgent: String = "",
        platform: String = "iPhone",
        deviceLabel: String = ""
    ) {
        self.mode = mode
        self.userAgent = userAgent
        self.platform = platform
        self.deviceLabel = deviceLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(FingerprintMode.self, forKey: .mode) ?? .stealthSafari
        userAgent = try container.decodeIfPresent(String.self, forKey: .userAgent) ?? ""
        platform = try container.decodeIfPresent(String.self, forKey: .platform) ?? "iPhone"
        deviceLabel = try container.decodeIfPresent(String.self, forKey: .deviceLabel) ?? ""
    }

    static func defaultSafari() -> FingerprintConfig {
        FingerprintConfig(
            mode: .defaultSafari,
            userAgent: "",
            platform: "iPhone",
            deviceLabel: "This Device"
        )
    }

    static func stealth(device: DeviceProfile) -> FingerprintConfig {
        FingerprintConfig(
            mode: .stealthSafari,
            userAgent: device.userAgent,
            platform: device.platform,
            deviceLabel: device.label
        )
    }

    static func randomized() -> FingerprintConfig {
        let device = deviceProfiles.randomElement()!
        return .stealth(device: device)
    }

    static let deviceProfiles: [DeviceProfile] = [
        DeviceProfile(
            label: "iPhone 17 Pro Max",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 440, screenHeight: 956,
            availWidth: 440, availHeight: 956, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 17 Pro",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 402, screenHeight: 874,
            availWidth: 402, availHeight: 874, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 16 Pro Max",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 430, screenHeight: 932,
            availWidth: 430, availHeight: 932, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 16 Pro",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 393, screenHeight: 852,
            availWidth: 393, availHeight: 852, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 16",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 393, screenHeight: 852,
            availWidth: 393, availHeight: 852, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 15 Pro Max",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 430, screenHeight: 932,
            availWidth: 430, availHeight: 932, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 15 Pro",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 393, screenHeight: 852,
            availWidth: 393, availHeight: 852, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPad Pro 13\" M4",
            userAgent: "Mozilla/5.0 (iPad; CPU OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPad", screenWidth: 1032, screenHeight: 1376,
            availWidth: 1032, availHeight: 1376, pixelRatio: 2.0,
            hardwareConcurrency: 10, deviceMemory: 16, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "MacBook Pro 16\" (Safari)",
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15",
            platform: "MacIntel", screenWidth: 1728, screenHeight: 1117,
            availWidth: 1728, availHeight: 1055, pixelRatio: 2.0,
            hardwareConcurrency: 12, deviceMemory: 36, maxTouchPoints: 0
        ),
    ]
}
