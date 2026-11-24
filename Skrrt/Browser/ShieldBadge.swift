import SwiftUI

struct ShieldBadge: View {
    let tab: Tab

    @Environment(Settings.self) private var settings

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Image(systemName: status.symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(status.tint)
                Text(status.title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .capsule)
        }
        .buttonStyle(PressStyle())
        .animation(.smooth(duration: 0.3), value: status)
    }

    private var status: Status {
        if tab.isPrivate { return .privateTab }
        if !tab.isSecure { return .exposed }
        return settings.blocksContent ? .protected : .open
    }

    private func toggle() {
        settings.blocksContent.toggle()
    }

    private enum Status {
        case privateTab
        case protected
        case exposed
        case open

        var symbol: String {
            switch self {
            case .privateTab: "eye.slash.fill"
            case .protected: "checkmark.shield.fill"
            case .exposed: "exclamationmark.shield.fill"
            case .open: "shield.slash.fill"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .privateTab: "Private"
            case .protected: "Protected"
            case .exposed: "Not Secure"
            case .open: "Shield Off"
            }
        }

        var tint: Color {
            switch self {
            case .privateTab, .protected: Palette.blue
            case .exposed, .open: .primary
            }
        }
    }
}
