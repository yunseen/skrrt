import Foundation

extension URL {
    var displayHost: String {
        guard let host else { return absoluteString }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
