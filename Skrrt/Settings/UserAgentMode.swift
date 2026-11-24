import Foundation

enum UserAgentMode: String, CaseIterable, Identifiable {
    case safari
    case chrome
    case desktop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safari: "Safari"
        case .chrome: "Chrome"
        case .desktop: "Desktop"
        }
    }

    var userAgent: String? {
        switch self {
        case .chrome:
            "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/140.0.0.0 Mobile/15E148 Safari/604.1"
        case .safari, .desktop:
            nil
        }
    }
}
