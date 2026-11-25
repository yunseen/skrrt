import Foundation
import WebKit

/// Answers requests from plugin scripts. It only listens in the isolated plugin world, so web pages cannot call it,
/// and it checks every request against the permissions of the plugin that sent it.
@MainActor
final class PluginBridge: NSObject, WKScriptMessageHandlerWithReply {
    weak var plugins: PluginStore?
    weak var rules: SiteRules?

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = 12
        return URLSession(configuration: configuration)
    }()

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let body = message.body as? [String: Any], let operation = body["op"] as? String else {
            return (nil, "Bad message")
        }
        switch operation {
        case "fetch":
            return await fetch(body)
        case "hide":
            return hide(body, from: message)
        default:
            return (nil, "Unknown operation")
        }
    }

    // MARK: Network

    private func fetch(_ body: [String: Any]) async -> (Any?, String?) {
        guard let pluginID = body["plugin"] as? String,
              let plugin = plugins?.plugin(pluginID), plugin.isEnabled,
              let text = body["url"] as? String, let url = URL(string: text),
              url.scheme == "https", let host = url.host else {
            return (nil, "Request refused")
        }
        guard plugin.permissions.allows(host: host) else {
            return (nil, "\(host) is not in the permissions of this plugin")
        }
        var request = URLRequest(url: url)
        let options = body["init"] as? [String: Any] ?? [:]
        let method = (options["method"] as? String ?? "GET").uppercased()
        guard method == "GET" || method == "POST" else { return (nil, "Method not allowed") }
        request.httpMethod = method
        if let headers = options["headers"] as? [String: Any] {
            for (name, value) in headers {
                let lower = name.lowercased()
                guard lower != "cookie", lower != "host", let text = value as? String else { continue }
                request.setValue(text, forHTTPHeaderField: name)
            }
        }
        if method == "POST", let payload = options["body"] as? String {
            request.httpBody = Data(payload.utf8)
        }
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(decoding: data.prefix(2_000_000), as: UTF8.self)
            return (["ok": (200..<300).contains(status), "status": status, "body": text], nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    // MARK: Hiding elements

    private func hide(_ body: [String: Any], from message: WKScriptMessage) -> (Any?, String?) {
        guard let selector = body["selector"] as? String, !selector.isEmpty, selector.count < 400,
              let host = message.webView?.url?.host else {
            return (nil, "Nothing to hide")
        }
        rules?.add(selector, host: host)
        return (true, nil)
    }
}
