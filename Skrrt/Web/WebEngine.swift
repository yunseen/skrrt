import WebKit

@MainActor
enum WebEngine {
    static func configuration(isPrivate: Bool) -> WKWebViewConfiguration {
        WKWebViewConfiguration()
    }

    static func clearWebsiteData() async {}
}
