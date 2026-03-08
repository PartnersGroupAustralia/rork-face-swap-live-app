import Foundation

struct FingerprintConfig: Codable, Sendable, Hashable {
    nonisolated var userAgent: String
    nonisolated var platform: String
    nonisolated var vendor: String
    nonisolated var languages: [String]
    nonisolated var hardwareConcurrency: Int
    nonisolated var deviceMemory: Int
    nonisolated var maxTouchPoints: Int
    nonisolated var screenWidth: Int
    nonisolated var screenHeight: Int
    nonisolated var availWidth: Int
    nonisolated var availHeight: Int
    nonisolated var colorDepth: Int
    nonisolated var pixelRatio: Double
    nonisolated var timezone: String
    nonisolated var timezoneOffset: Int
    nonisolated var webGLVendor: String
    nonisolated var webGLRenderer: String
    nonisolated var canvasSeed: Int
    nonisolated var audioSeed: Int
    nonisolated var doNotTrack: String
    nonisolated var blockWebRTC: Bool
    nonisolated var spoofFonts: Bool

    static let deviceProfiles: [DeviceProfile] = [
        DeviceProfile(
            label: "iPhone 15 Pro",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 393, screenHeight: 852,
            availWidth: 393, availHeight: 852, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 16 Pro Max",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 440, screenHeight: 956,
            availWidth: 440, availHeight: 956, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 8, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPhone 14",
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Mobile/15E148 Safari/604.1",
            platform: "iPhone", screenWidth: 390, screenHeight: 844,
            availWidth: 390, availHeight: 844, pixelRatio: 3.0,
            hardwareConcurrency: 6, deviceMemory: 6, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "iPad Pro 12.9",
            userAgent: "Mozilla/5.0 (iPad; CPU OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
            platform: "iPad", screenWidth: 1024, screenHeight: 1366,
            availWidth: 1024, availHeight: 1366, pixelRatio: 2.0,
            hardwareConcurrency: 8, deviceMemory: 16, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "MacBook Pro (Safari)",
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15",
            platform: "MacIntel", screenWidth: 1512, screenHeight: 982,
            availWidth: 1512, availHeight: 929, pixelRatio: 2.0,
            hardwareConcurrency: 12, deviceMemory: 16, maxTouchPoints: 0
        ),
        DeviceProfile(
            label: "Windows Chrome",
            userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            platform: "Win32", screenWidth: 1920, screenHeight: 1080,
            availWidth: 1920, availHeight: 1040, pixelRatio: 1.0,
            hardwareConcurrency: 16, deviceMemory: 8, maxTouchPoints: 0
        ),
        DeviceProfile(
            label: "Pixel 8 Pro",
            userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.135 Mobile Safari/537.36",
            platform: "Linux armv81", screenWidth: 412, screenHeight: 892,
            availWidth: 412, availHeight: 892, pixelRatio: 2.625,
            hardwareConcurrency: 8, deviceMemory: 12, maxTouchPoints: 5
        ),
        DeviceProfile(
            label: "Samsung Galaxy S24",
            userAgent: "Mozilla/5.0 (Linux; Android 14; SM-S921B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.135 Mobile Safari/537.36",
            platform: "Linux armv81", screenWidth: 360, screenHeight: 780,
            availWidth: 360, availHeight: 780, pixelRatio: 3.0,
            hardwareConcurrency: 8, deviceMemory: 8, maxTouchPoints: 5
        )
    ]

    static let timezones: [(label: String, zone: String, offset: Int)] = [
        ("UTC", "UTC", 0),
        ("New York (EST)", "America/New_York", 300),
        ("Chicago (CST)", "America/Chicago", 360),
        ("Denver (MST)", "America/Denver", 420),
        ("Los Angeles (PST)", "America/Los_Angeles", 480),
        ("London (GMT)", "Europe/London", 0),
        ("Berlin (CET)", "Europe/Berlin", -60),
        ("Tokyo (JST)", "Asia/Tokyo", -540),
        ("Sydney (AEST)", "Australia/Sydney", -660),
        ("Dubai (GST)", "Asia/Dubai", -240),
    ]

    static let languageSets: [(label: String, langs: [String])] = [
        ("English (US)", ["en-US", "en"]),
        ("English (UK)", ["en-GB", "en"]),
        ("German", ["de-DE", "de", "en"]),
        ("French", ["fr-FR", "fr", "en"]),
        ("Spanish", ["es-ES", "es", "en"]),
        ("Portuguese (BR)", ["pt-BR", "pt", "en"]),
        ("Japanese", ["ja-JP", "ja", "en"]),
        ("Chinese (Simplified)", ["zh-CN", "zh", "en"]),
        ("Korean", ["ko-KR", "ko", "en"]),
        ("Arabic", ["ar-SA", "ar", "en"]),
    ]

    static func randomized() -> FingerprintConfig {
        let profile = deviceProfiles.randomElement()!
        let tz = timezones.randomElement()!
        let lang = languageSets.randomElement() ?? languageSets[0]

        return FingerprintConfig(
            userAgent: profile.userAgent,
            platform: profile.platform,
            vendor: "Apple Computer, Inc.",
            languages: lang.langs,
            hardwareConcurrency: profile.hardwareConcurrency,
            deviceMemory: profile.deviceMemory,
            maxTouchPoints: profile.maxTouchPoints,
            screenWidth: profile.screenWidth,
            screenHeight: profile.screenHeight,
            availWidth: profile.availWidth,
            availHeight: profile.availHeight,
            colorDepth: 32,
            pixelRatio: profile.pixelRatio,
            timezone: tz.zone,
            timezoneOffset: tz.offset,
            webGLVendor: "Apple Inc.",
            webGLRenderer: "Apple GPU",
            canvasSeed: Int.random(in: 100000...999999),
            audioSeed: Int.random(in: 100000...999999),
            doNotTrack: "unspecified",
            blockWebRTC: true,
            spoofFonts: true
        )
    }

    static func from(device: DeviceProfile) -> FingerprintConfig {
        let tz = timezones.randomElement()!
        let lang = languageSets.randomElement() ?? languageSets[0]

        let vendor: String
        let glVendor: String
        let glRenderer: String

        if device.platform == "Win32" {
            vendor = "Google Inc."
            glVendor = "Google Inc. (NVIDIA)"
            glRenderer = "ANGLE (NVIDIA, NVIDIA GeForce RTX 4070 Direct3D11 vs_5_0 ps_5_0, D3D11)"
        } else if device.platform.contains("Linux") {
            vendor = "Google Inc."
            glVendor = "Qualcomm"
            glRenderer = "Adreno (TM) 750"
        } else {
            vendor = "Apple Computer, Inc."
            glVendor = "Apple Inc."
            glRenderer = "Apple GPU"
        }

        return FingerprintConfig(
            userAgent: device.userAgent,
            platform: device.platform,
            vendor: vendor,
            languages: lang.langs,
            hardwareConcurrency: device.hardwareConcurrency,
            deviceMemory: device.deviceMemory,
            maxTouchPoints: device.maxTouchPoints,
            screenWidth: device.screenWidth,
            screenHeight: device.screenHeight,
            availWidth: device.availWidth,
            availHeight: device.availHeight,
            colorDepth: 32,
            pixelRatio: device.pixelRatio,
            timezone: tz.zone,
            timezoneOffset: tz.offset,
            webGLVendor: glVendor,
            webGLRenderer: glRenderer,
            canvasSeed: Int.random(in: 100000...999999),
            audioSeed: Int.random(in: 100000...999999),
            doNotTrack: "unspecified",
            blockWebRTC: true,
            spoofFonts: true
        )
    }
}
