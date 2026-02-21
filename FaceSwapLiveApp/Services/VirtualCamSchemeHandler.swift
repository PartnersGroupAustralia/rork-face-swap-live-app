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
        let requestURL = urlSchemeTask.request.url!

        if method == "OPTIONS" {
            guard let response = HTTPURLResponse(
                url: requestURL,
                statusCode: 204,
                httpVersion: "HTTP/1.1",
                headerFields: corsHeaders()
            ) else {
                urlSchemeTask.didFailWithError(URLError(.unknown))
                return
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        guard let fileURL = videoFileURL else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let attrs: [FileAttributeKey: Any]
        do {
            attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        } catch {
            urlSchemeTask.didFailWithError(URLError(.cannotOpenFile))
            return
        }

        let fileSize = (attrs[.size] as? UInt64) ?? 0
        let mime = mimeType(for: fileURL)

        if method == "HEAD" {
            var headers = corsHeaders()
            headers["Content-Type"] = mime
            headers["Content-Length"] = "\(fileSize)"
            headers["Accept-Ranges"] = "bytes"
            guard let response = HTTPURLResponse(
                url: requestURL,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) else {
                urlSchemeTask.didFailWithError(URLError(.unknown))
                return
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        let rangeHeader = urlSchemeTask.request.value(forHTTPHeaderField: "Range")

        if let rangeHeader, rangeHeader.hasPrefix("bytes=") {
            let rangeSpec = String(rangeHeader.dropFirst(6))
            let parts = rangeSpec.split(separator: "-", maxSplits: 1)
            let start = UInt64(parts[0]) ?? 0
            let end: UInt64
            if parts.count > 1 && !parts[1].isEmpty {
                end = min(UInt64(parts[1]) ?? (fileSize - 1), fileSize - 1)
            } else {
                end = fileSize - 1
            }

            guard start < fileSize else {
                var headers = corsHeaders()
                headers["Content-Range"] = "bytes */\(fileSize)"
                let resp = HTTPURLResponse(
                    url: requestURL,
                    statusCode: 416,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                urlSchemeTask.didReceive(resp)
                urlSchemeTask.didReceive(Data())
                urlSchemeTask.didFinish()
                return
            }

            guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
                urlSchemeTask.didFailWithError(URLError(.cannotOpenFile))
                return
            }
            handle.seek(toFileOffset: start)
            let length = end - start + 1
            let data = handle.readData(ofLength: Int(length))
            try? handle.close()

            var headers = corsHeaders()
            headers["Content-Type"] = mime
            headers["Content-Length"] = "\(data.count)"
            headers["Content-Range"] = "bytes \(start)-\(end)/\(fileSize)"
            headers["Accept-Ranges"] = "bytes"

            guard let response = HTTPURLResponse(
                url: requestURL,
                statusCode: 206,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) else {
                urlSchemeTask.didFailWithError(URLError(.unknown))
                return
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.cannotOpenFile))
            return
        }

        var headers = corsHeaders()
        headers["Content-Type"] = mime
        headers["Content-Length"] = "\(data.count)"
        headers["Accept-Ranges"] = "bytes"

        guard let response = HTTPURLResponse(
            url: requestURL,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else {
            urlSchemeTask.didFailWithError(URLError(.unknown))
            return
        }

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        case "mp4": return "video/mp4"
        case "webm": return "video/webm"
        default: return "video/mp4"
        }
    }

    private func corsHeaders() -> [String: String] {
        [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Max-Age": "86400"
        ]
    }
}
