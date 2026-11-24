import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SearchSection()
                HomeScreenSection()
                AppearanceSection()
                PrivacySection()
                Section {
                    NavigationLink {
                        ExtensionsView()
                    } label: {
                        Label("Extensions", systemImage: "puzzlepiece.extension")
                    }
                } footer: {
                    Text("Hide cookie banners, force dark mode or add your own scripts and styles.")
                }
                GeneralSection()
                AboutSection()
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
}
