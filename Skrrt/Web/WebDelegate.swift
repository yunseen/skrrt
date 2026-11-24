import UIKit
import WebKit

@MainActor
final class WebDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    var prefersDesktop = false
    var onFinish: (@MainActor () -> Void)?
    var onOpen: (@MainActor (URL) -> Void)?

    private static let webSchemes: Set<String> = ["http", "https", "about", "blob", "data", "file", "javascript"]

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        if let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(),
           !Self.webSchemes.contains(scheme) {
            _ = await UIApplication.shared.open(url)
            return (.cancel, preferences)
        }
        preferences.preferredContentMode = prefersDesktop ? .desktop : .mobile
        return (.allow, preferences)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish?()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        show(error, in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        show(error, in: webView)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            onOpen?(url)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        await Dialogs.alert(message: message, host: frame.request.url?.host)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        await Dialogs.confirm(message: message, host: frame.request.url?.host)
    }

    private func show(_ error: any Error, in webView: WKWebView) {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain, nsError.code != NSURLErrorCancelled else { return }
        let failing = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        webView.loadHTMLString(ErrorPage.html(for: nsError, url: failing), baseURL: failing)
    }
}
