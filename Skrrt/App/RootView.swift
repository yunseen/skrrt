import SwiftData
import SwiftUI

enum Sheet: String, Identifiable {
    case library
    case settings

    var id: String { rawValue }
}

struct RootView: View {
    @Environment(TabStore.self) private var tabs
    @Environment(Settings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var showsSwitcher = false
    @State private var sheet: Sheet?

    var body: some View {
        ZStack {
            BrowserView(showSwitcher: presentSwitcher, openSheet: { sheet = $0 })
            if showsSwitcher {
                TabSwitcherView(dismiss: { showsSwitcher = false })
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.smooth(duration: 0.4), value: showsSwitcher)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .library:
                LibraryView { url in
                    guard let tab = tabs.current else { return }
                    tab.load(url)
                }
            case .settings:
                SettingsView()
            }
        }
        .task {
            tabs.recorder = { title, url in
                context.insert(HistoryEntry(title: title, url: url))
            }
            await tabs.prepare()
        }
        .onChange(of: settings.userAgent) {
            tabs.applyUserAgent()
        }
        .onChange(of: settings.blocksContent) {
            tabs.applyBlocking()
            tabs.current?.reload()
        }
    }

    private func presentSwitcher() {
        Task {
            await tabs.current?.captureSnapshot()
            showsSwitcher = true
        }
    }
}
