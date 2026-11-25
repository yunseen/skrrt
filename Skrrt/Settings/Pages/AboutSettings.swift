import SwiftUI

struct AboutSettings: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
                LabeledContent("Plugin API", value: PluginRuntime.apiVersion)
            }
            Section {
                Link(destination: PluginDocs.url) {
                    Label("Documentation", systemImage: "book.closed")
                }
                if let url = URL(string: "https://github.com/yunseen/skrrt") {
                    Link(destination: url) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            } footer: {
                Text("Skrrt is free software released under the GPL-3.0 license.")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
