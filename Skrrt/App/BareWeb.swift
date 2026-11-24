import SwiftUI
import WebKit

struct BareWeb: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.load(URLRequest(url: URL(string: "https://example.com")!))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}
}
