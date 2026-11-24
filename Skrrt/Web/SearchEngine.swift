import Foundation

enum SearchEngine {
    static func resolve(_ input: String, template: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let url = directURL(text) {
            return url
        }
        return search(text, template: template)
    }

    static func directURL(_ text: String) -> URL? {
        if let url = URL(string: text), let scheme = url.scheme?.lowercased(), ["http", "https", "file", "about"].contains(scheme) {
            return url
        }
        if looksLikeHost(text), let url = URL(string: "https://\(text)") {
            return url
        }
        return nil
    }

    static func search(_ query: String, template: String) -> URL? {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#?"))
        let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query
        return URL(string: template.replacingOccurrences(of: "%s", with: encoded))
    }

    private static func looksLikeHost(_ text: String) -> Bool {
        guard !text.contains(" ") else { return false }
        if text.lowercased().hasPrefix("localhost") { return true }
        guard text.contains("."), let host = URL(string: "https://\(text)")?.host else { return false }
        let labels = host.split(separator: ".")
        guard let last = labels.last else { return false }
        let isNamed = last.count >= 2 && last.allSatisfy(\.isLetter)
        let isAddress = labels.count == 4 && labels.allSatisfy { $0.allSatisfy(\.isNumber) }
        return isNamed || isAddress
    }
}

enum SuggestionService {
    static func fetch(_ query: String, engine: SearchEngineKind) async -> [String] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#?"))
        let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
        guard let url = URL(string: engine.suggestTemplate.replacingOccurrences(of: "%s", with: encoded)) else { return [] }
        var request = URLRequest(url: url, timeoutInterval: 4)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              json.count > 1 else { return [] }
        if let strings = json[1] as? [String] {
            return Array(strings.prefix(8))
        }
        if let objects = json[1] as? [[String: Any]] {
            return Array(objects.compactMap { $0["phrase"] as? String }.prefix(8))
        }
        return []
    }
}
