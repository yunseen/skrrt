import SwiftUI

struct GeneralSection: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Site Mode", selection: $settings.userAgent) {
                ForEach(UserAgentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            LabeledContent("Search Engine", value: "Google")
        } header: {
            Text("General")
        } footer: {
            Text("Chrome mode identifies Skrrt as Chrome. Desktop mode asks sites for their desktop version.")
        }
    }
}
