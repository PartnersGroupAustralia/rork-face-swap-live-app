import Foundation

nonisolated struct DeviceProfile: Codable, Sendable, Hashable, Identifiable {
    var id: String { label }
    let label: String
    let userAgent: String
    let platform: String
    let screenWidth: Int
    let screenHeight: Int
    let availWidth: Int
    let availHeight: Int
    let pixelRatio: Double
    let hardwareConcurrency: Int
    let deviceMemory: Int
    let maxTouchPoints: Int
}
