import SwiftUI

struct AddressBar: View {
    let tab: Tab
    let openSearch: () -> Void
    let openSite: () -> Void

    @Environment(Settings.self) private var settings
    @Environment(PluginStore.self) private var plugins

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: leadingSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tab.url != nil && tab.isSecure ? Color.accentColor : Color.secondary)
            field
            trailing
        }
        .padding(.horizontal, 18)
        .frame(height: tab.isCompact ? 40 : 52)
        .contentShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
        .overlay(alignment: .bottomLeading) { progressBar }
        .simultaneousGesture(
            DragGesture(minimumDistance: 14).onEnded { value in
                if value.translation.height < -20 { begin() }
            }
        )
    }

    private var field: some View {
        Button(action: begin) {
            Group {
                if let url = tab.url {
                    Text(verbatim: url.displayHost)
                } else {
                    Text("Search or enter address")
                }
            }
            .font(.system(size: tab.isCompact ? 14 : 16, weight: .medium))
            .foregroundStyle(tab.url == nil ? .secondary : .primary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .concealed()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var trailing: some View {
        if tab.url != nil && !tab.isCompact {
            Button(action: openSite) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(activePlugins > 0 ? Color.accentColor : Color.secondary)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
                    .overlay(alignment: .topTrailing) {
                        if activePlugins > 0 {
                            Text(verbatim: "\(activePlugins)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .frame(minWidth: 14, minHeight: 14)
                                .background(Color.accentColor, in: Capsule())
                                .offset(x: 2, y: 1)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("This Site"))
            if settings.showsShield {
                Button {
                    settings.blocksContent.toggle()
                } label: {
                    Image(systemName: shieldSymbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(shieldColor)
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(shieldLabel))
            }
            Button {
                if tab.isLoading { tab.stop() } else { tab.reload() }
            } label: {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if tab.isLoading {
            Capsule()
                .fill(Color.accentColor)
                .frame(height: 3)
                .scaleEffect(x: max(tab.progress, 0.06), anchor: .leading)
                .animation(.smooth(duration: 0.3), value: tab.progress)
                .padding(.horizontal, 26)
                .padding(.bottom, 4)
                .transition(.opacity)
        }
    }

    private var activePlugins: Int {
        guard let host = tab.url?.host else { return 0 }
        return plugins.items.filter { $0.isActive(on: host) }.count
    }

    private var leadingSymbol: String {
        guard tab.url != nil else { return "magnifyingglass" }
        return tab.isSecure ? "lock.fill" : "exclamationmark.triangle.fill"
    }

    private var shieldSymbol: String {
        if tab.isPrivate { return "eye.slash.fill" }
        if !tab.isSecure { return "exclamationmark.shield.fill" }
        return settings.blocksContent ? "checkmark.shield.fill" : "shield.slash.fill"
    }

    private var shieldColor: Color {
        if tab.isPrivate { return .accentColor }
        if !tab.isSecure { return .orange }
        return settings.blocksContent ? .accentColor : .secondary
    }

    private var shieldLabel: LocalizedStringKey {
        if tab.isPrivate { return "Private" }
        if !tab.isSecure { return "Not Secure" }
        return settings.blocksContent ? "Protected" : "Shield Off"
    }

    private func begin() {
        if tab.isCompact {
            tab.expand()
            return
        }
        openSearch()
    }
}
