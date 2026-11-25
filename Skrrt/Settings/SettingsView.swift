import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PluginStore.self) private var plugins

    var body: some View {
        NavigationStack {
            List {
                Section {
                    link(SearchSettings(), "Search", "magnifyingglass", Color(red: 0.039, green: 0.518, blue: 1))
                    link(HomeSettings(), "Home Screen", "square.grid.2x2.fill", Color(red: 0.62, green: 0.45, blue: 1))
                    link(AppearanceSettings(), "Appearance", "paintpalette.fill", Color(red: 1, green: 0.36, blue: 0.62))
                }
                Section {
                    link(PrivacySettings(), "Privacy and Security", "hand.raised.fill", Color(red: 0.2, green: 0.78, blue: 0.45))
                    link(BrowsingSettings(), "Browsing", "safari.fill", Color(red: 1, green: 0.58, blue: 0.15))
                }
                Section {
                    NavigationLink {
                        PluginsHomeView()
                    } label: {
                        HStack {
                            IconLabel("Plugins", "puzzlepiece.extension.fill", Color(red: 0.2, green: 0.8, blue: 0.95))
                            Spacer()
                            Text(verbatim: "\(plugins.enabledCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Scripts and styles that change how websites look and work.")
                }
                Section {
                    link(AboutSettings(), "About", "info.circle.fill", Color.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func link<Destination: View>(
        _ destination: Destination,
        _ title: LocalizedStringKey,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            IconLabel(title, symbol, color)
        }
    }
}
