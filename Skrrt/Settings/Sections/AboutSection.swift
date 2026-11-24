import SwiftUI

struct AboutSection: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        Section {
            LabeledContent("Version", value: version)
            if let url = URL(string: "https://github.com/yunseen/skrrt") {
                Link("Source Code", destination: url)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Skrrt is free software released under the GPL-3.0 license.")
        }
    }
}
