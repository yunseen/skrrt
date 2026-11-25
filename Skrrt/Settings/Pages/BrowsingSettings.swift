import SwiftUI

struct BrowsingSettings: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.restoresTabs) {
                    IconLabel("Restore Tabs on Launch", "arrow.counterclockwise", Color(red: 1, green: 0.58, blue: 0.15))
                }
                Toggle(isOn: $settings.collapsesBars) {
                    IconLabel("Hide Bars While Scrolling", "rectangle.compress.vertical", Color(red: 0.039, green: 0.518, blue: 1))
                }
                Toggle(isOn: $settings.showsShield) {
                    IconLabel("Show Protection Badge", "checkmark.shield.fill", Color(red: 0.2, green: 0.78, blue: 0.45))
                }
            } header: {
                Text("Tabs and Pages")
            } footer: {
                Text("The protection badge sits under the Dynamic Island. Tap it to turn blocking on or off.")
            }

            Section {
                Picker(selection: $settings.language) {
                    ForEach(Language.allCases) { language in
                        Text(language.title).tag(language)
                    }
                } label: {
                    IconLabel("Language", "globe", Color(red: 0.62, green: 0.45, blue: 1))
                }
            }

            Section {
                Toggle(isOn: $settings.webInspector) {
                    IconLabel("Web Inspector", "ladybug.fill", Color(red: 0.55, green: 0.55, blue: 0.58))
                }
                Link(destination: PluginDocs.url) {
                    Label("Plugin Documentation", systemImage: "book.closed")
                }
            } header: {
                Text("For Developers")
            } footer: {
                Text("Turn on Web Inspector to debug pages and plugins from Safari on a Mac.")
            }
        }
        .navigationTitle("Browsing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
