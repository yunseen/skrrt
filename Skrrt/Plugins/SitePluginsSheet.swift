import SwiftUI
import WebKit

/// The window of the current site, like the popup of Chrome extensions: which plugins work here,
/// a switch for each of them, and the tools that belong to a site, such as cookies and hidden elements.
struct SitePluginsSheet: View {
    let tab: Tab

    @Environment(\.dismiss) private var dismiss
    @Environment(PluginStore.self) private var store
    @Environment(SiteRules.self) private var rules
    @Environment(Settings.self) private var settings
    @State private var confirmsClearing = false
    @State private var cookieCount: Int?

    private var host: String {
        (tab.url?.host ?? "").replacingOccurrences(of: "www.", with: "")
    }

    private var language: String { settings.languageCode }

    private var matching: [Plugin] {
        store.plugins(for: host)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    if matching.isEmpty {
                        VStack(spacing: 6) {
                            Text("No plugins for this site")
                                .font(.headline)
                            Text("Get plugins from the store and they will appear here.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(matching) { plugin in
                            NavigationLink {
                                PluginDetailView(pluginID: plugin.id)
                            } label: {
                                row(plugin)
                            }
                        }
                    }
                } header: {
                    Text("Plugins on This Site")
                }

                Section {
                    Button {
                        tab.startElementPicker(language: language)
                        dismiss()
                    } label: {
                        IconLabel("Hide an Element", "eye.slash.fill", Color(red: 1, green: 0.27, blue: 0.23))
                            .foregroundStyle(.primary)
                    }
                    NavigationLink {
                        HiddenElementsView(host: host)
                    } label: {
                        HStack {
                            IconLabel("Hidden Elements", "rectangle.dashed", Color(red: 0.62, green: 0.45, blue: 1))
                            Spacer()
                            Text(verbatim: "\(rules.rules[SiteRules.clean(host)]?.count ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        CookieManagerView(tab: tab)
                    } label: {
                        HStack {
                            IconLabel("Cookies", "circle.hexagongrid.fill", Color(red: 1, green: 0.58, blue: 0.15))
                            Spacer()
                            if let cookieCount {
                                Text(verbatim: "\(cookieCount)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button(role: .destructive) {
                        confirmsClearing = true
                    } label: {
                        Label("Clear Site Data", systemImage: "trash")
                    }
                } header: {
                    Text("Tools")
                }

                Section {
                    NavigationLink {
                        PluginsHomeView()
                    } label: {
                        IconLabel("Get More Plugins", "puzzlepiece.extension.fill", Color(red: 0.2, green: 0.8, blue: 0.95))
                    }
                }
            }
            .navigationTitle("This Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                cookieCount = await CookieManagerView.cookies(for: host, in: tab).count
            }
            .confirmationDialog("Clear the data of this site?", isPresented: $confirmsClearing, titleVisibility: .visible) {
                Button("Clear Site Data", role: .destructive) {
                    Task {
                        await clearSiteData()
                        dismiss()
                        tab.reload()
                    }
                }
            } message: {
                Text("Cookies, stored data and cache of this site are removed. You will be signed out.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            PluginIconView(icon: PluginIcon(symbol: "globe", color: "#0A84FF", logoHost: host.isEmpty ? nil : host), size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: host)
                    .font(.headline)
                    .lineLimit(1)
                let active = matching.filter { $0.isActive(on: host) }.count
                Text("\(active) plugins active")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func row(_ plugin: Plugin) -> some View {
        HStack(spacing: 12) {
            PluginIconView(icon: plugin.icon, size: 40)
                .opacity(plugin.isActive(on: host) ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: plugin.name.text(language))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                if !plugin.isEnabled {
                    Text("Turned off everywhere")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(verbatim: plugin.summary.text(language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { store.plugin(plugin.id)?.isActive(on: host) ?? false },
                set: { store.setActive(plugin.id, on: host, $0) }
            ))
            .labelsHidden()
        }
    }

    private func clearSiteData() async {
        let dataStore = tab.webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let records = await dataStore.dataRecords(ofTypes: types)
        let matching = records.filter { record in
            let name = record.displayName.lowercased()
            return host == name || host.hasSuffix("." + name) || name.hasSuffix("." + host)
        }
        await dataStore.removeData(ofTypes: types, for: matching)
    }
}

struct HiddenElementsView: View {
    let host: String

    @Environment(SiteRules.self) private var rules

    private var selectors: [String] {
        rules.rules[SiteRules.clean(host)] ?? []
    }

    var body: some View {
        List {
            if selectors.isEmpty {
                ContentUnavailableView(
                    "Nothing Hidden",
                    systemImage: "eye",
                    description: Text("Use Hide an Element in the site window, then tap what you do not want to see.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(selectors, id: \.self) { selector in
                        Text(verbatim: selector)
                            .font(.system(.footnote, design: .monospaced))
                            .swipeActions {
                                Button("Show", role: .destructive) {
                                    rules.remove(selector, host: host)
                                }
                            }
                    }
                } footer: {
                    Text("Swipe an item to show it again. Reload the page to see the change.")
                }
                Section {
                    Button("Show All", role: .destructive) {
                        rules.removeAll(host: host)
                    }
                }
            }
        }
        .navigationTitle("Hidden Elements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
