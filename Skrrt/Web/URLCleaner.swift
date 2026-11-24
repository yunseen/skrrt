import Foundation

enum URLCleaner {
    private static let trackingPrefixes = ["utm_", "mc_", "pk_", "hsa_"]
    private static let trackingNames: Set<String> = [
        "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "yclid",
        "igshid", "mkt_tok", "_ga", "_gl", "vero_id", "twclid", "ttclid"
    ]

    static func rewrite(_ url: URL, upgradeHTTPS: Bool, stripTracking: Bool) -> URL? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var changed = false

        if upgradeHTTPS, scheme == "http", let host = components.host,
           host != "localhost", !host.hasSuffix(".local"), !isAddress(host),
           components.port == nil || components.port == 80 {
            components.scheme = "https"
            components.port = nil
            changed = true
        }

        if stripTracking, let items = components.queryItems, !items.isEmpty {
            let kept = items.filter { item in
                let name = item.name.lowercased()
                return !trackingNames.contains(name) && !trackingPrefixes.contains { name.hasPrefix($0) }
            }
            if kept.count != items.count {
                components.queryItems = kept.isEmpty ? nil : kept
                changed = true
            }
        }

        return changed ? components.url : nil
    }

    private static func isAddress(_ host: String) -> Bool {
        host.contains(":") || host.split(separator: ".").allSatisfy { $0.allSatisfy(\.isNumber) }
    }
}
