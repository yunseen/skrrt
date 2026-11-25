import SwiftData
import SwiftUI

@main
struct SkrrtApp: App {
    private let container: ModelContainer
    @State private var settings: Settings
    @State private var plugins: PluginStore
    @State private var rules: SiteRules
    @State private var catalog = PluginCatalog()
    @State private var shortcuts: ShortcutStore
    @State private var tabs: TabStore
    @State private var keyboard = KeyboardState()

    init() {
        let settings = Settings()
        let plugins = PluginStore()
        let rules = SiteRules()
        _settings = State(initialValue: settings)
        _plugins = State(initialValue: plugins)
        _rules = State(initialValue: rules)
        _shortcuts = State(initialValue: ShortcutStore())
        _tabs = State(initialValue: TabStore(settings: settings, plugins: plugins, rules: rules))
        if let disk = try? ModelContainer(for: Bookmark.self, HistoryEntry.self) {
            container = disk
        } else if let memory = try? ModelContainer(
            for: Bookmark.self, HistoryEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            container = memory
        } else {
            fatalError("Unable to create the data store")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(tabs)
                .environment(shortcuts)
                .environment(plugins)
                .environment(rules)
                .environment(catalog)
                .environment(keyboard)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(settings.accentColor)
        }
        .modelContainer(container)
    }
}
