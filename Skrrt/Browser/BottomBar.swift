import SwiftUI

struct BottomBar: View {
    let tab: Tab
    let showSwitcher: () -> Void
    let openSheet: (Sheet) -> Void
    let addBookmark: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 10) {
                AddressBar(tab: tab)
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
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
