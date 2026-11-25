import SwiftUI

struct BottomBar: View {
    let tab: Tab
    let showSwitcher: () -> Void
    let showSearch: () -> Void
    let openSheet: (Sheet) -> Void
    let addBookmark: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 12) {
                AddressBar(tab: tab, openSearch: showSearch, openSite: { openSheet(.site) })
                if !tab.isCompact {
                    ToolbarRow(
                        tab: tab,
                        showSwitcher: showSwitcher,
                        openSheet: openSheet,
                        addBookmark: addBookmark
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .containerRelativeFrame(.horizontal) { length, _ in
            length - Metrics.edgeInset * 2
        }
        .padding(.bottom, 6)
        .animation(.smooth(duration: 0.3), value: tab.isCompact)
    }
}
