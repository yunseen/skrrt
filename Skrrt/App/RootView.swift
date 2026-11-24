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

    var body: some View {
        if let tab = tabs.current {
            WebContainer(webView: tab.webView, bottomInset: 0).ignoresSafeArea().task { tab.load(URL(string: "https://example.com")!) }.overlay(alignment: .top) { ShieldBadge(tab: tab) }
        }
    }
}
