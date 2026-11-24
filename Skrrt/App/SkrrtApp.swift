import SwiftData
import SwiftUI

@main
struct SkrrtApp: App {
    private let container: ModelContainer
    @State private var settings: Settings
    @State private var extensions: ExtensionStore
    @State private var shortcuts: ShortcutStore
    @State private var tabs: TabStore

    init() {
        let settings = Settings()
        let extensions = ExtensionStore()
        _settings = State(initialValue: settings)
        _extensions = State(initialValue: extensions)
        _shortcuts = State(initialValue: ShortcutStore())
        _tabs = State(initialValue: TabStore(settings: settings, extensions: extensions))
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
                .environment(extensions)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(settings.accentColor)
        }
        .modelContainer(container)
    }
}
