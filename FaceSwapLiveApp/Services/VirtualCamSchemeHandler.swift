import WebKit

nonisolated final class VirtualCamSchemeHandler: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    private let lock = NSLock()
    private var _videoFileURL: URL?

    var videoFileURL: URL? {
        get { lock.withLock { _videoFileURL } }
        set { lock.withLock { _videoFileURL = newValue } }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let method = urlSchemeTask.request.httpMethod?.uppercased() ?? "GET"

        if method == "OPTIONS" {
            guard let response = HTTPURLResponse(
                url: urlSchemeTask.request.url!,
                statusCode: 204,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Max-Age": "86400"
                ]
            ) else {
                urlSchemeTask.didFailWithError(URLError(.unknown))
                return
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        guard let fileURL = videoFileURL,
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "mov": mime = "video/quicktime"
        case "m4v": mime = "video/x-m4v"
        default: mime = "video/mp4"
        }

        guard let response = HTTPURLResponse(
            url: urlSchemeTask.request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mime,
                "Content-Length": "\(data.count)",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "*"
            ]
        ) else {
            urlSchemeTask.didFailWithError(URLError(.unknown))
            return
        }

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}
