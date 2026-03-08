import SwiftUI

struct CookieShareSheet: UIViewControllerRepresentable {
    let data: Data
    let profileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let sanitizedName = profileName.replacingOccurrences(of: " ", with: "_").lowercased()
        let fileName = "\(sanitizedName)_cookies.json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
