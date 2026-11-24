import SwiftData
import SwiftUI

struct PrivacySection: View {
    @Environment(Settings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var confirmsClearing = false

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Block Ads and Trackers", isOn: $settings.blocksContent)
            Toggle("Hide Addresses", isOn: $settings.hidesAddresses)
            Button("Clear Browsing Data", role: .destructive) {
                confirmsClearing = true
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Hidden addresses appear as dots in tab and library lists. Tap one to reveal it for five seconds.")
        }
        .confirmationDialog("Clear all history and website data?", isPresented: $confirmsClearing, titleVisibility: .visible) {
            Button("Clear Everything", role: .destructive) {
                Task {
                    await WebEngine.clearWebsiteData()
                    try? context.delete(model: HistoryEntry.self)
                }
            }
        }
    }
}
