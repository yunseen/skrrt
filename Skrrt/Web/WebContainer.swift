import SwiftUI
import WebKit

struct WebContainer: UIViewRepresentable {
    let webView: WKWebView
    let bottomInset: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let scrollView = view.scrollView
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }
}
