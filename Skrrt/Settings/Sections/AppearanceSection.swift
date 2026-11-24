import SwiftUI

struct AppearanceSection: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Appearance") {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(Appearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
