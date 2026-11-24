import SwiftData
import SwiftUI

@main
struct SkrrtApp: App {
    private let container: ModelContainer
    @State private var settings: Settings
    @State private var tabs: TabStore

    init() {
        let settings = Settings()
        _settings = State(initialValue: settings)
        _tabs = State(initialValue: TabStore(settings: settings))
        do {
            container = try ModelContainer(for: Bookmark.self, HistoryEntry.self)
        } catch {
            fatalError("Unable to open the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            BareWeb().ignoresSafeArea()
        }
        .modelContainer(container)
    }
}
