import Foundation

enum FingerprintSpoofEngine {

    static func spoofScript(for config: FingerprintConfig) -> String? {
        if config.mode == .defaultSafari {
            return nil
        }
        if config.mode == .stealthSafari {
            return nil
        }
        return nil
    }

    static func customUserAgent(for config: FingerprintConfig) -> String? {
        switch config.mode {
        case .defaultSafari:
            return nil
        case .stealthSafari:
            if !config.userAgent.isEmpty {
                return config.userAgent
            }
            return nil
        }
    }
}
