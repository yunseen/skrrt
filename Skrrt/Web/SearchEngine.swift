import Foundation

enum SearchEngine {
    static func resolve(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let url = URL(string: text), let scheme = url.scheme?.lowercased(), ["http", "https", "file", "about"].contains(scheme) {
            return url
        }
        if looksLikeHost(text), let url = URL(string: "https://\(text)") {
            return url
        }
        return search(text)
    }

    static func search(_ query: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
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
