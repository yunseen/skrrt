import SwiftUI

/// A rounded, colored symbol tile like the ones in the iOS Settings app.
struct SettingsIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
    }
}

struct IconLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color

    init(_ title: LocalizedStringKey, _ symbol: String, _ color: Color) {
        self.title = title
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            SettingsIcon(symbol: symbol, color: color)
        }
    }
}

/// A selectable card with a symbol, used for themes and tile shapes.
struct ChoiceCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                }
        }
        .buttonStyle(.plain)
    }
}

struct EngineBadge: View {
    let engine: SearchEngineKind

    var body: some View {
        Group {
            if engine == .custom {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Text(verbatim: letter)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .foregroundStyle(.white)
        .frame(width: 30, height: 30)
        .background(color.gradient, in: Circle())
    }

    private var letter: String {
        switch engine {
        case .duckduckgo: "D"
        case .brave: "B"
        case .startpage: "S"
        case .ecosia: "E"
        case .yandex: "Я"
        case .bing: "b"
        case .google: "G"
        case .custom: ""
        }
    }

    private var color: Color {
        switch engine {
        case .duckduckgo: Color(red: 0.87, green: 0.34, blue: 0.13)
        case .brave: Color(red: 0.98, green: 0.35, blue: 0.16)
        case .startpage: Color(red: 0.23, green: 0.33, blue: 0.85)
        case .ecosia: Color(red: 0.2, green: 0.62, blue: 0.3)
        case .yandex: Color(red: 0.95, green: 0.15, blue: 0.15)
        case .bing: Color(red: 0.0, green: 0.55, blue: 0.62)
        case .google: Color(red: 0.26, green: 0.52, blue: 0.96)
        case .custom: Color.gray
        }
    }
}
