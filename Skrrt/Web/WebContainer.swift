import SwiftUI
import WebKit

struct WebContainer: UIViewRepresentable {
    let webView: WKWebView
    let bottomInset: CGFloat

    func makeUIView(context: Context) -> UIView {
        let host = UIView()
        webView.removeFromSuperview()
        webView.frame = host.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(webView)
        return host
    }

    func updateUIView(_ view: UIView, context: Context) {
        let scrollView = webView.scrollView
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }
}
