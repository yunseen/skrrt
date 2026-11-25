import SwiftData
import SwiftUI

enum Sheet: String, Identifiable {
    case library
    case settings
    case site

    var id: String { rawValue }
}

struct RootView: View {
    @Environment(TabStore.self) private var tabs
    @Environment(Settings.self) private var settings
    @Environment(PluginStore.self) private var plugins
    @Environment(SiteRules.self) private var rules
    @Environment(\.modelContext) private var context
    @State private var showsSwitcher = false
    @State private var showsSearch = false
    @State private var sheet: Sheet?

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            BrowserView(
                showSwitcher: presentSwitcher,
                showSearch: { showsSearch = true },
                openSheet: { sheet = $0 }
            )
            .environment(\.wallpaperPaused, showsSwitcher || showsSearch || sheet != nil)
            if showsSwitcher {
                TabSwitcherView(dismiss: { showsSwitcher = false })
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .zIndex(1)
            }
            if showsSearch, let tab = tabs.current {
                SearchView(tab: tab, dismiss: { showsSearch = false })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.smooth(duration: 0.4), value: showsSwitcher)
        .animation(.smooth(duration: 0.35), value: showsSearch)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .library:
                LibraryView { url in
                    guard let tab = tabs.current else { return }
                    tab.load(url)
                }
            case .settings:
                SettingsView()
            case .site:
                if let tab = tabs.current {
                    SitePluginsSheet(tab: tab)
                }
            }
        }
        .task {
            tabs.start()
            tabs.recorder = { title, url in
                context.insert(HistoryEntry(title: title, url: url))
            }
            plugins.onChange = {
                tabs.applyPreferences()
                tabs.current?.reload()
            }
            rules.onChange = {
                tabs.applyPreferences()
            }
            if settings.clearsOnLaunch {
                await WebEngine.clearWebsiteData()
                try? context.delete(model: HistoryEntry.self)
            }
            await tabs.prepare()
        }
        .onChange(of: settings.blocksContent) {
            tabs.applyBlocking()
            tabs.current?.reload()
        }
        .onChange(of: settings.darkPages) {
            tabs.applyPreferences()
            tabs.current?.reload()
        }
        .onChange(of: settings.smartDark) {
            tabs.applyPreferences()
            tabs.current?.reload()
        }
        .onChange(of: settings.webInspector) { tabs.applyPreferences() }
        .onChange(of: settings.collapsesBars) { tabs.applyPreferences() }
        .onChange(of: settings.appearance) { tabs.applyPreferences() }
        .onChange(of: settings.upgradesHTTPS) { tabs.applyPreferences() }
        .onChange(of: settings.stripsTracking) { tabs.applyPreferences() }
        .onChange(of: settings.blocksPopups) { tabs.applyPreferences() }
        .onChange(of: settings.allowsJavaScript) {
            tabs.applyPreferences()
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
