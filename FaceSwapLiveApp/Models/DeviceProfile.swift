import Foundation

struct DeviceProfile: Codable, Sendable, Hashable, Identifiable {
    nonisolated var id: String { label }
    nonisolated let label: String
    nonisolated let userAgent: String
    nonisolated let platform: String
    nonisolated let screenWidth: Int
    nonisolated let screenHeight: Int
    nonisolated let availWidth: Int
    nonisolated let availHeight: Int
    nonisolated let pixelRatio: Double
    nonisolated let hardwareConcurrency: Int
    nonisolated let deviceMemory: Int
    nonisolated let maxTouchPoints: Int
}
