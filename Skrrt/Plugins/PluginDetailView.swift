import SwiftUI

/// The window of a plugin, like the page of an extension: what it does, its settings, what it may access and the way to remove it.
struct PluginDetailView: View {
    private let entry: StoreEntry?
    private let pluginID: String?

    @Environment(PluginStore.self) private var store
    @Environment(PluginCatalog.self) private var catalog
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var preview: Plugin?
    @State private var confirmsRemoval = false
    @State private var renameText = ""
    @State private var renaming = false
    @State private var editing: PluginDraft?

    init(entry: StoreEntry) {
        self.entry = entry
        pluginID = nil
    }

    init(pluginID: String) {
        self.pluginID = pluginID
        entry = nil
    }

    private var language: String { settings.languageCode }

    private var installed: Plugin? {
        if let pluginID { return store.plugin(pluginID) }
        if let entry { return store.installed(storeID: entry.id) }
        return nil
    }

    private var plugin: Plugin? {
        installed ?? preview
    }

    private var storeEntry: StoreEntry? {
        if let entry { return entry }
        if let storeID = installed?.storeID { return catalog.entry(storeID) }
        return nil
    }

    var body: some View {
        List {
            if let plugin {
                Section {
                    header(plugin)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                if let installed {
                    Section {
                        Toggle(isOn: Binding(
                            get: { store.plugin(installed.id)?.isEnabled ?? false },
                            set: { store.setEnabled(installed.id, $0) }
                        )) {
                            IconLabel("Enabled", "power", Color(red: 0.2, green: 0.78, blue: 0.45))
                        }
                    }
                }

                let details = plugin.details.text(language)
                if !details.isEmpty {
                    Section {
                        Text(verbatim: details)
                            .font(.callout)
                    } header: {
                        Text("About")
                    }
                }

                if !plugin.options.isEmpty {
                    Section {
                        if let installed {
                            PluginOptionsForm(pluginID: installed.id)
                            if !installed.values.isEmpty {
                                Button("Reset to Defaults", role: .destructive) {
                                    store.resetValues(installed.id)
                                }
                            }
                        } else {
                            Text("Settings: \(plugin.options.count). You can change them after installing.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Settings")
                    }
                }

                Section {
                    permissionRows(plugin)
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("A plugin never sees your tabs, history, passwords or the data of the app.")
                }

                if let installed, !installed.blockedHosts.isEmpty {
                    Section {
                        ForEach(installed.blockedHosts, id: \.self) { host in
                            HStack {
                                Text(verbatim: host)
                                Spacer()
                                Button("Turn On") {
                                    store.unblock(installed.id, host: host)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    } header: {
                        Text("Turned Off on These Sites")
                    }
                }

                Section {
                    LabeledContent("Version", value: plugin.version)
                    if !plugin.author.isEmpty {
                        LabeledContent("Author", value: plugin.author)
                    }
                    LabeledContent("Category") {
                        Text(plugin.category.title)
                    }
                } header: {
                    Text("Information")
                }

                if let installed {
                    Section {
                        if installed.isUser {
                            Button("Edit", systemImage: "pencil") {
                                editing = PluginDraft(existing: installed, kind: installed.kind)
                            }
                            Button("Rename", systemImage: "character.cursor.ibeam") {
                                renameText = installed.name.text("en")
                                renaming = true
                            }
                        }
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            store.duplicate(installed.id)
                        }
                        ShareLink(item: installed.exportSource, subject: Text(verbatim: installed.name.text("en"))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button("Remove Plugin", systemImage: "trash", role: .destructive) {
                            confirmsRemoval = true
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(plugin?.name.text(language) ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if installed == nil, let entry {
                preview = await catalog.preview(entry)
            }
        }
        .confirmationDialog("Remove this plugin?", isPresented: $confirmsRemoval, titleVisibility: .visible) {
            Button("Remove Plugin", role: .destructive) {
                if let id = installed?.id {
                    store.uninstall(id)
                    if pluginID != nil { dismiss() }
                }
            }
        } message: {
            Text("Its settings are removed too. You can get it again from the store.")
        }
        .alert("Rename", isPresented: $renaming) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let id = installed?.id { store.rename(id, to: renameText) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $editing) { draft in
            PluginEditor(draft: draft)
        }
    }

    private func header(_ plugin: Plugin) -> some View {
        HStack(alignment: .center, spacing: 16) {
            PluginIconView(icon: plugin.icon, size: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: plugin.name.text(language))
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                Text(verbatim: plugin.summary.text(language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                if let storeEntry, !plugin.isUser {
                    GetButton(entry: storeEntry)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func permissionRows(_ plugin: Plugin) -> some View {
        if plugin.isUser {
            row("exclamationmark.shield", .orange, Text("Runs code you added yourself. Only use code you trust."))
        }
        if plugin.matches.isEmpty {
            row("globe", .blue, Text("Works on every website you open."))
        } else {
            row("globe", .blue, Text("Works on: \(plugin.matches.joined(separator: ", "))"))
        }
        if plugin.permissions.hosts.isEmpty {
            row("lock.shield", .green, Text("Works only inside the page and does not contact other servers."))
        } else {
            row("network", .purple, Text("Contacts: \(plugin.permissions.hosts.joined(separator: ", "))"))
        }
        if !plugin.permissions.tools.isEmpty {
            row("wrench.and.screwdriver", .orange, Text("Uses: \(plugin.permissions.tools.joined(separator: ", "))"))
        }
    }

    private func row(_ symbol: String, _ color: Color, _ text: Text) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(symbol: symbol, color: color, size: 28)
            text
                .font(.callout)
        }
    }
}

/// Builds the settings window of a plugin from the options in its manifest.
struct PluginOptionsForm: View {
    let pluginID: String

    @Environment(PluginStore.self) private var store

    var body: some View {
        if let plugin = store.plugin(pluginID) {
            ForEach(plugin.options) { option in
                OptionRow(pluginID: pluginID, option: option)
            }
        }
    }
}

private struct OptionRow: View {
    let pluginID: String
    let option: PluginOption

    @Environment(PluginStore.self) private var store
    @Environment(Settings.self) private var settings
    @State private var sliderValue: Double = 0

    private var language: String { settings.languageCode }

    private var current: OptionValue {
        guard let plugin = store.plugin(pluginID) else { return option.defaultValue }
        return plugin.value(for: option)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch option.type {
            case .toggle:
                Toggle(isOn: Binding(
                    get: { current.boolValue },
                    set: { store.setValue(pluginID, key: option.key, .bool($0)) }
                )) {
                    Text(verbatim: option.title.text(language))
                }
            case .slider:
                sliderRow
            case .choice:
                Text(verbatim: option.title.text(language))
                    .font(.subheadline.weight(.semibold))
                ForEach(option.choices ?? []) { choice in
                    Button {
                        store.setValue(pluginID, key: option.key, .text(choice.value))
                    } label: {
                        HStack {
                            Text(verbatim: choice.title.text(language))
                                .foregroundStyle(.primary)
                            Spacer()
                            if current.textValue == choice.value {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            case .multichoice:
                Text(verbatim: option.title.text(language))
                    .font(.subheadline.weight(.semibold))
                ForEach(option.choices ?? []) { choice in
                    Toggle(isOn: Binding(
                        get: { current.listValue.contains(choice.value) },
                        set: { isOn in
                            var list = current.listValue
                            list.removeAll { $0 == choice.value }
                            if isOn { list.append(choice.value) }
                            store.setValue(pluginID, key: option.key, .list(list))
                        }
                    )) {
                        Text(verbatim: choice.title.text(language))
                    }
                }
            case .text:
                Text(verbatim: option.title.text(language))
                    .font(.subheadline.weight(.semibold))
                TextField("", text: Binding(
                    get: { current.textValue },
                    set: { store.setValue(pluginID, key: option.key, .text($0)) }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
            if let hint = option.hint?.text(language), !hint.isEmpty {
                Text(verbatim: hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var sliderRow: some View {
        let low = option.min ?? 0
        let high = option.max ?? 100
        let step = option.step ?? 1
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: option.title.text(language))
                Spacer()
                Text(verbatim: format(sliderValue) + (option.unit ?? ""))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $sliderValue, in: low...high, step: step) { editing in
                if !editing {
                    store.setValue(pluginID, key: option.key, .number(sliderValue))
                }
            }
        }
        .onAppear { sliderValue = current.numberValue }
    }

    private func format(_ value: Double) -> String {
        let step = option.step ?? 1
        return step < 1 ? String(format: "%.2f", value) : String(Int(value.rounded()))
    }
}
