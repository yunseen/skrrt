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
            Toggle("Upgrade to HTTPS", isOn: $settings.upgradesHTTPS)
            Toggle("Remove Tracking Parameters", isOn: $settings.stripsTracking)
            Toggle("Block Pop-ups", isOn: $settings.blocksPopups)
            Toggle("JavaScript", isOn: $settings.allowsJavaScript)
            Toggle("Hide Addresses", isOn: $settings.hidesAddresses)
            Toggle("Clear Data on Launch", isOn: $settings.clearsOnLaunch)
            Button("Clear Browsing Data", role: .destructive) {
                confirmsClearing = true
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Hidden addresses appear as dots in tab and library lists. Touch and hold one to reveal it for five seconds. Tracking parameters are links like utm_source or fbclid.")
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
