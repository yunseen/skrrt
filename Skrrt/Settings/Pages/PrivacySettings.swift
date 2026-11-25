import SwiftData
import SwiftUI

struct PrivacySettings: View {
    @Environment(Settings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var confirmsClearing = false

    private let green = Color(red: 0.2, green: 0.78, blue: 0.45)
    private let blue = Color(red: 0.039, green: 0.518, blue: 1)
    private let red = Color(red: 1, green: 0.27, blue: 0.23)
    private let orange = Color(red: 1, green: 0.58, blue: 0.15)
    private let violet = Color(red: 0.62, green: 0.45, blue: 1)

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.blocksContent) {
                    IconLabel("Block Ads and Trackers", "checkmark.shield.fill", green)
                }
                Toggle(isOn: $settings.upgradesHTTPS) {
                    IconLabel("Upgrade to HTTPS", "lock.fill", blue)
                }
                Toggle(isOn: $settings.stripsTracking) {
                    IconLabel("Remove Tracking Parameters", "scissors", orange)
                }
                Toggle(isOn: $settings.blocksPopups) {
                    IconLabel("Block Pop-ups", "xmark.rectangle.fill", red)
                }
            } header: {
                Text("Protection")
            } footer: {
                Text("Tracking parameters are links like utm_source or fbclid. Pop-ups opened by a tap on a link are still allowed.")
            }

            Section {
                Toggle(isOn: $settings.allowsJavaScript) {
                    IconLabel("JavaScript", "curlybraces", violet)
                }
            } footer: {
                Text("Turning JavaScript off breaks many sites and stops plugins from running.")
            }

            Section {
                Toggle(isOn: $settings.hidesAddresses) {
                    IconLabel("Hide Addresses", "eye.slash.fill", violet)
                }
                Toggle(isOn: $settings.clearsOnLaunch) {
                    IconLabel("Clear Data on Launch", "clock.arrow.circlepath", orange)
                }
                Button(role: .destructive) {
                    confirmsClearing = true
                } label: {
                    Label("Clear Browsing Data", systemImage: "trash.fill")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Hidden addresses appear as dots in tab and library lists. Touch and hold one to reveal it for five seconds.")
            }
        }
        .navigationTitle("Privacy and Security")
        .navigationBarTitleDisplayMode(.inline)
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
