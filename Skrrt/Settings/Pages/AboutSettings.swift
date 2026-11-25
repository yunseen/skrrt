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
                HStack(spacing: 6) {
                    Text("Skrrt is free software released under the GPL-3.0 license.")
                    AnimatedEmoji(index: Emoji.heart)
                        .frame(width: 22, height: 22)
                }
            }
            Section {
                Text("Animated emoji: the AnimatedAsianEmoji pack. Developer logos: the Developer Emojis pack by @danulqua. They belong to their authors.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Credits")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
