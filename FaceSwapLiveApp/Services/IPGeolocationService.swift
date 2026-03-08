import Foundation

nonisolated struct IPGeoResult: Sendable {
    let timezone: String
    let countryCode: String
    let ip: String
}

enum IPGeolocationService {
    static func detect() async -> IPGeoResult? {
        guard let url = URL(string: "https://ipapi.co/json/") else { return nil }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(IPAPIResponse.self, from: data)
            return IPGeoResult(
                timezone: decoded.timezone ?? "UTC",
                countryCode: decoded.country_code ?? "US",
                ip: decoded.ip ?? ""
            )
        } catch {
            return nil
        }
    }
}

private nonisolated struct IPAPIResponse: Codable, Sendable {
    let ip: String?
    let country_code: String?
    let timezone: String?
    let languages: String?
}
