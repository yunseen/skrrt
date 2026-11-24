import UIKit

enum IconFetcher {
    private static let agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    static func normalize(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        let candidate = text.contains("://") ? text : "https://\(text)"
        guard let url = URL(string: candidate), let host = url.host, host.contains(".") || host == "localhost" else { return nil }
        return url
    }

    static func fetch(for url: URL) async -> UIImage? {
        guard let host = url.host else { return nil }
        var candidates: [URL] = []
        if let html = await text(from: url) {
            candidates += iconLinks(in: html, base: url)
        }
        if let root = URL(string: "\(url.scheme ?? "https")://\(host)") {
            candidates.append(root.appendingPathComponent("apple-touch-icon.png"))
            candidates.append(root.appendingPathComponent("favicon.ico"))
        }
        if let service = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
            candidates.append(service)
        }
        for candidate in candidates {
            if let image = await image(from: candidate), image.size.width >= 24 {
                return normalized(image)
            }
        }
        return nil
    }

    private static func request(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func text(from url: URL) async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(for: request(url)) else { return nil }
        return String(decoding: data.prefix(300_000), as: UTF8.self)
    }

    private static func image(from url: URL) async -> UIImage? {
        guard let (data, response) = try? await URLSession.shared.data(for: request(url)) else { return nil }
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 { return nil }
        return UIImage(data: data)
    }

    private static func iconLinks(in html: String, base: URL) -> [URL] {
        guard let tagPattern = try? NSRegularExpression(pattern: "<link\\s[^>]*>", options: [.caseInsensitive]) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        var found: [(score: Int, url: URL)] = []
        for match in tagPattern.matches(in: html, range: range) {
            guard let tagRange = Range(match.range, in: html) else { continue }
            let tag = String(html[tagRange])
            guard let rel = attribute("rel", in: tag)?.lowercased(), rel.contains("icon"),
                  let href = attribute("href", in: tag),
                  let resolved = URL(string: href, relativeTo: base)?.absoluteURL else { continue }
            var score = rel.contains("apple-touch-icon") ? 1000 : 0
            if let sizes = attribute("sizes", in: tag), let width = Int(sizes.split(separator: "x").first ?? "") {
                score += min(width, 512)
            }
            if resolved.pathExtension.lowercased() == "svg" { score -= 2000 }
            found.append((score, resolved))
        }
        return found.sorted { $0.score > $1.score }.map(\.url)
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        let pattern = "\(name)\\s*=\\s*[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
              let range = Range(match.range(at: 1), in: tag) else { return nil }
        return String(tag[range])
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        let side: CGFloat = 128
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
}
