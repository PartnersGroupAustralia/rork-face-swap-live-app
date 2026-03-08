import Foundation

nonisolated struct FingerprintConfig: Codable, Sendable, Hashable {
    var userAgent: String
    var platform: String
    var vendor: String
    var languages: [String]
    var hardwareConcurrency: Int
    var deviceMemory: Int
    var maxTouchPoints: Int
    var screenWidth: Int
    var screenHeight: Int
    var availWidth: Int
    var availHeight: Int
    var colorDepth: Int
    var pixelRatio: Double
    var timezone: String
    var timezoneOffset: Int
    var webGLVendor: String
    var webGLRenderer: String
    var canvasSeed: Int
    var audioSeed: Int
    var doNotTrack: String
    var blockWebRTC: Bool
    var spoofFonts: Bool
    var autoDetectFromIP: Bool

    init(
        userAgent: String = "",
        platform: String = "",
        vendor: String = "Apple Computer, Inc.",
        languages: [String] = ["en-US", "en"],
        hardwareConcurrency: Int = 6,
        deviceMemory: Int = 8,
        maxTouchPoints: Int = 5,
        screenWidth: Int = 393,
        screenHeight: Int = 852,
        availWidth: Int = 393,
        availHeight: Int = 852,
        colorDepth: Int = 32,
        pixelRatio: Double = 3.0,
        timezone: String = "America/New_York",
        timezoneOffset: Int = 300,
        webGLVendor: String = "Apple Inc.",
        webGLRenderer: String = "Apple GPU",
        canvasSeed: Int = Int.random(in: 100000...999999),
        audioSeed: Int = Int.random(in: 100000...999999),
        doNotTrack: String = "unspecified",
        blockWebRTC: Bool = true,
        spoofFonts: Bool = true,
        autoDetectFromIP: Bool = false
    ) {
        self.userAgent = userAgent
        self.platform = platform
        self.vendor = vendor
        self.languages = languages
        self.hardwareConcurrency = hardwareConcurrency
        self.deviceMemory = deviceMemory
        self.maxTouchPoints = maxTouchPoints
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.availWidth = availWidth
        self.availHeight = availHeight
        self.colorDepth = colorDepth
        self.pixelRatio = pixelRatio
        self.timezone = timezone
        self.timezoneOffset = timezoneOffset
        self.webGLVendor = webGLVendor
        self.webGLRenderer = webGLRenderer
        self.canvasSeed = canvasSeed
        self.audioSeed = audioSeed
        self.doNotTrack = doNotTrack
        self.blockWebRTC = blockWebRTC
        self.spoofFonts = spoofFonts
        self.autoDetectFromIP = autoDetectFromIP
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userAgent = try container.decode(String.self, forKey: .userAgent)
        platform = try container.decode(String.self, forKey: .platform)
        vendor = try container.decode(String.self, forKey: .vendor)
        languages = try container.decode([String].self, forKey: .languages)
        hardwareConcurrency = try container.decode(Int.self, forKey: .hardwareConcurrency)
        deviceMemory = try container.decode(Int.self, forKey: .deviceMemory)
        maxTouchPoints = try container.decode(Int.self, forKey: .maxTouchPoints)
        screenWidth = try container.decode(Int.self, forKey: .screenWidth)
        screenHeight = try container.decode(Int.self, forKey: .screenHeight)
        availWidth = try container.decode(Int.self, forKey: .availWidth)
        availHeight = try container.decode(Int.self, forKey: .availHeight)
        colorDepth = try container.decode(Int.self, forKey: .colorDepth)
        pixelRatio = try container.decode(Double.self, forKey: .pixelRatio)
        timezone = try container.decode(String.self, forKey: .timezone)
        timezoneOffset = try container.decode(Int.self, forKey: .timezoneOffset)
        webGLVendor = try container.decode(String.self, forKey: .webGLVendor)
        webGLRenderer = try container.decode(String.self, forKey: .webGLRenderer)
        canvasSeed = try container.decode(Int.self, forKey: .canvasSeed)
        audioSeed = try container.decode(Int.self, forKey: .audioSeed)
        doNotTrack = try container.decode(String.self, forKey: .doNotTrack)
        blockWebRTC = try container.decode(Bool.self, forKey: .blockWebRTC)
        spoofFonts = try container.decode(Bool.self, forKey: .spoofFonts)
        autoDetectFromIP = try container.decodeIfPresent(Bool.self, forKey: .autoDetectFromIP) ?? false
    }

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
        ("Auto (Based on IP)", "", 0),
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
        ("Auto (Based on IP)", []),
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
        let tz = timezones.filter { !$0.zone.isEmpty }.randomElement()!
        let lang = languageSets.filter { !$0.langs.isEmpty }.randomElement() ?? languageSets[1]

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
            spoofFonts: true,
            autoDetectFromIP: false
        )
    }

    static func from(device: DeviceProfile) -> FingerprintConfig {
        let tz = timezones.filter { !$0.zone.isEmpty }.randomElement()!
        let lang = languageSets.filter { !$0.langs.isEmpty }.randomElement() ?? languageSets[1]

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
            spoofFonts: true,
            autoDetectFromIP: false
        )
    }

    static let timezoneToOffset: [String: Int] = [
        "UTC": 0,
        "America/New_York": 300,
        "America/Chicago": 360,
        "America/Denver": 420,
        "America/Los_Angeles": 480,
        "America/Sao_Paulo": 180,
        "America/Argentina/Buenos_Aires": 180,
        "America/Mexico_City": 360,
        "America/Bogota": 300,
        "America/Lima": 300,
        "Europe/London": 0,
        "Europe/Berlin": -60,
        "Europe/Paris": -60,
        "Europe/Madrid": -60,
        "Europe/Rome": -60,
        "Europe/Amsterdam": -60,
        "Europe/Moscow": -180,
        "Europe/Istanbul": -180,
        "Europe/Warsaw": -60,
        "Europe/Bucharest": -120,
        "Asia/Tokyo": -540,
        "Asia/Shanghai": -480,
        "Asia/Hong_Kong": -480,
        "Asia/Seoul": -540,
        "Asia/Singapore": -480,
        "Asia/Dubai": -240,
        "Asia/Kolkata": -330,
        "Asia/Bangkok": -420,
        "Asia/Jakarta": -420,
        "Asia/Taipei": -480,
        "Australia/Sydney": -660,
        "Australia/Melbourne": -660,
        "Pacific/Auckland": -720,
        "Africa/Cairo": -120,
        "Africa/Lagos": -60,
        "Africa/Johannesburg": -120,
    ]

    static let countryToLanguage: [String: [String]] = [
        "US": ["en-US", "en"],
        "GB": ["en-GB", "en"],
        "CA": ["en-CA", "en"],
        "AU": ["en-AU", "en"],
        "DE": ["de-DE", "de", "en"],
        "FR": ["fr-FR", "fr", "en"],
        "ES": ["es-ES", "es", "en"],
        "IT": ["it-IT", "it", "en"],
        "PT": ["pt-PT", "pt", "en"],
        "BR": ["pt-BR", "pt", "en"],
        "JP": ["ja-JP", "ja", "en"],
        "CN": ["zh-CN", "zh", "en"],
        "KR": ["ko-KR", "ko", "en"],
        "RU": ["ru-RU", "ru", "en"],
        "SA": ["ar-SA", "ar", "en"],
        "AE": ["ar-AE", "ar", "en"],
        "IN": ["hi-IN", "hi", "en"],
        "NL": ["nl-NL", "nl", "en"],
        "TR": ["tr-TR", "tr", "en"],
        "PL": ["pl-PL", "pl", "en"],
        "MX": ["es-MX", "es", "en"],
        "AR": ["es-AR", "es", "en"],
        "TH": ["th-TH", "th", "en"],
        "ID": ["id-ID", "id", "en"],
        "SG": ["en-SG", "en"],
        "HK": ["zh-HK", "zh", "en"],
        "TW": ["zh-TW", "zh", "en"],
    ]
}
