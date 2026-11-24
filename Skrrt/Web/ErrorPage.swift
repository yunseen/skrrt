import Foundation

enum ErrorPage {
    static func html(for error: NSError, url: URL?) -> String {
        let address = (url?.absoluteString ?? "").htmlEscaped
        let reason = error.localizedDescription.htmlEscaped
        return """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <style>
        body { font: -apple-system-body; display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 90vh; margin: 0; padding: 24px; text-align: center; background: Canvas; color: CanvasText; }
        h1 { font-size: 28px; margin: 0 0 8px; }
        p { margin: 4px 0; opacity: 0.65; word-break: break-word; }
        .dot { width: 14px; height: 14px; border-radius: 7px; background: #0A84FF; margin-bottom: 20px; }
        </style>
        </head>
        <body>
        <div class="dot"></div>
        <h1>\(String(localized: "Cannot Open Page"))</h1>
        <p>\(reason)</p>
        <p>\(address)</p>
        </body>
        </html>
        """
    }
}

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
