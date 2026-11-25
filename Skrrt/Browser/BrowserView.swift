import SwiftData
import SwiftUI

struct BrowserView: View {
    let showSwitcher: () -> Void
    let showSearch: () -> Void
    let openSheet: (Sheet) -> Void

    @Environment(TabStore.self) private var tabs
    @Environment(Settings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var toast: LocalizedStringKey?

    var body: some View {
        ZStack(alignment: .top) {
            if let tab = tabs.current {
                page(for: tab)
                top(for: tab)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let tab = tabs.current {
                BottomBar(
                    tab: tab,
                    showSwitcher: showSwitcher,
                    showSearch: showSearch,
                    openSheet: openSheet,
                    addBookmark: { addBookmark(for: tab) }
                )
            }
        }
        .animation(.smooth(duration: 0.35), value: tabs.current?.isCompact)
    }

    @ViewBuilder
    private func page(for tab: Tab) -> some View {
        if tab.url == nil {
            StartPage(tab: tab)
                .id(tab.id)
        } else {
            WebContainer(webView: tab.webView, bottomInset: 0)
                .ignoresSafeArea(edges: .top)
                .id(tab.id)
        }
    }

    private func top(for tab: Tab) -> some View {
        VStack(spacing: 8) {
            if tab.url != nil && !tab.isCompact && settings.showsShield {
                ShieldBadge(tab: tab)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            if let toast {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.bouncy(duration: 0.45), value: tab.isCompact)
    }

    private func addBookmark(for tab: Tab) {
        guard let url = tab.url else { return }
        context.insert(Bookmark(title: tab.displayTitle, url: url))
        flash("Bookmark Added")
    }

    private func flash(_ message: LocalizedStringKey) {
        withAnimation(.smooth) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.smooth) { toast = nil }
        }
    }
}
