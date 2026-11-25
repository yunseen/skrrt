import SwiftUI

enum SearchEngineKind: String, CaseIterable, Identifiable {
    case duckduckgo
    case brave
    case startpage
    case ecosia
    case yandex
    case bing
    case google
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .google: LocalizedStringKey("Google")
        case .duckduckgo: LocalizedStringKey("DuckDuckGo")
        case .brave: LocalizedStringKey("Brave")
        case .bing: LocalizedStringKey("Bing")
        case .yandex: LocalizedStringKey("Yandex")
        case .startpage: LocalizedStringKey("Startpage")
        case .ecosia: LocalizedStringKey("Ecosia")
        case .custom: LocalizedStringKey("Custom")
        }
    }

    var searchTemplate: String {
        switch self {
        case .google: "https://www.google.com/search?q=%s"
        case .duckduckgo: "https://duckduckgo.com/?q=%s"
        case .brave: "https://search.brave.com/search?q=%s"
        case .bing: "https://www.bing.com/search?q=%s"
        case .yandex: "https://yandex.com/search/?text=%s"
        case .startpage: "https://www.startpage.com/do/search?q=%s"
        case .ecosia: "https://www.ecosia.org/search?q=%s"
        case .custom: "https://duckduckgo.com/?q=%s"
        }
    }

    var suggestTemplate: String {
        switch self {
        case .google: "https://suggestqueries.google.com/complete/search?client=firefox&q=%s"
        case .brave: "https://search.brave.com/api/suggest?q=%s"
        case .bing: "https://api.bing.com/osjson.aspx?query=%s"
        case .yandex: "https://suggest.yandex.com/suggest-ff.cgi?part=%s"
        case .ecosia: "https://ac.ecosia.org/autocomplete?type=list&q=%s"
        case .duckduckgo, .startpage, .custom: "https://duckduckgo.com/ac/?type=list&q=%s"
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case blue
    case cyan
    case violet
    case pink
    case red
    case orange
    case green
    case custom

    var id: String { rawValue }

    var preset: Color? {
        switch self {
        case .blue: Color(red: 0.039, green: 0.518, blue: 1)
        case .cyan: Color(red: 0.2, green: 0.8, blue: 0.95)
        case .violet: Color(red: 0.62, green: 0.45, blue: 1)
        case .pink: Color(red: 1, green: 0.36, blue: 0.62)
        case .red: Color(red: 1, green: 0.27, blue: 0.23)
        case .orange: Color(red: 1, green: 0.58, blue: 0.15)
        case .green: Color(red: 0.2, green: 0.78, blue: 0.45)
        case .custom: nil
        }
    }
}

enum WallpaperStyle: String, CaseIterable, Identifiable {
    case curtain
    case ice
    case aurora
    case photo

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .curtain: "Night Curtain"
        case .ice: "Ice"
        case .aurora: "Aurora"
        case .photo: "My Photo"
        }
    }
}

enum TileShape: String, CaseIterable, Identifiable {
    case squircle
    case circle

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .squircle: "Rounded"
        case .circle: "Circle"
        }
    }
}

enum DarkPages: String, CaseIterable, Identifiable {
    case off
    case auto
    case always

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .off: "Off"
        case .auto: "Match App"
        case .always: "Always"
        }
    }
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let number = UInt32(value, radix: 16) else { return nil }
        self.init(
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255
        )
    }

    var hexString: String {
        let color = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
