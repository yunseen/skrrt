import SwiftData
import SwiftUI

struct BrowserView: View {
    let showSwitcher: () -> Void
    let showSearch: () -> Void
    let openSheet: (Sheet) -> Void

    @Environment(TabStore.self) private var tabs
    @Environment(KeyboardState.self) private var keyboard
    @Environment(\.modelContext) private var context
    @State private var toast: LocalizedStringKey?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let tab = tabs.current {
                page(for: tab)
            }
        }
        .overlay(alignment: .bottom) { toastView }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let tab = tabs.current, !keyboard.isVisible {
                BottomBar(
                    tab: tab,
                    showSwitcher: showSwitcher,
                    showSearch: showSearch,
                    openSheet: openSheet,
                    addBookmark: { addBookmark(for: tab) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.25), value: keyboard.isVisible)
    }

    // The page stays inside the safe area so the header of a site is never under the status bar.
    // The area behind the status bar takes the color of the page, like in Safari.
    @ViewBuilder
    private func page(for tab: Tab) -> some View {
        if tab.url == nil {
            StartPage(tab: tab)
                .id(tab.id)
        } else {
            WebContainer(webView: tab.webView, bottomInset: 0)
                .background(Color(uiColor: tab.topColor).ignoresSafeArea())
                .id(tab.id)
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            HStack(spacing: 6) {
                AnimatedEmoji(index: Emoji.star)
                    .frame(width: 22, height: 22)
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
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
