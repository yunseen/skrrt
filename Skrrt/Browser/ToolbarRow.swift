import SwiftUI

struct ToolbarRow: View {
    let tab: Tab
    let showSwitcher: () -> Void
    let openSheet: (Sheet) -> Void
    let addBookmark: () -> Void

    @Environment(TabStore.self) private var tabs
    @Environment(Settings.self) private var settings

    var body: some View {
        HStack(spacing: 0) {
            GlassIconButton(symbol: "chevron.backward", isEnabled: tab.canGoBack) { tab.goBack() }
            Spacer(minLength: 4)
            GlassIconButton(symbol: "chevron.forward", isEnabled: tab.canGoForward) { tab.goForward() }
            Spacer(minLength: 4)
            share
            Spacer(minLength: 4)
            GlassIconButton(symbol: "book") { openSheet(.library) }
            Spacer(minLength: 4)
            tabsButton
            Spacer(minLength: 4)
            menu
        }
    }

    @ViewBuilder
    private var share: some View {
        if let url = tab.url {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: Metrics.symbolSize, weight: .semibold))
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                    .background(.ultraThinMaterial)
            }
            .buttonStyle(PressStyle())
        } else {
            GlassIconButton(symbol: "square.and.arrow.up", isEnabled: false) {}
        }
    }

    private var tabsButton: some View {
        Button(action: showSwitcher) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(lineWidth: 2)
                    .frame(width: 22, height: 22)
                Text("\(tabs.tabs.count)")
                    .font(.system(size: 11, weight: .bold))
                    .contentTransition(.numericText())
            }
            .frame(width: Metrics.controlSize, height: Metrics.controlSize)
            .background(.ultraThinMaterial)
        }
        .buttonStyle(PressStyle())
        .animation(.smooth, value: tabs.tabs.count)
    }

    private var menu: some View {
        @Bindable var settings = settings
        return Menu {
            Button("New Tab", systemImage: "plus") { tabs.open() }
            Button("New Private Tab", systemImage: "eye.slash") { tabs.open(isPrivate: true) }
            Divider()
            Button("Add Bookmark", systemImage: "star", action: addBookmark)
                .disabled(tab.url == nil)
            Picker("Site Mode", selection: $settings.userAgent) {
                ForEach(UserAgentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            Divider()
            Button("Settings", systemImage: "gearshape") { openSheet(.settings) }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: Metrics.symbolSize, weight: .semibold))
                .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                .background(.ultraThinMaterial)
        }
        .menuStyle(.button)
        .buttonStyle(PressStyle())
    }
}
