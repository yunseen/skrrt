import SwiftUI
import UniformTypeIdentifiers

enum PluginDocs {
    static let url = URL(string: "https://telegra.ph/Skrrt-plaginy-i-API-CSS-JavaScript-11-25")!
}

struct PluginsView: View {
    @Environment(PluginStore.self) private var store
    @Environment(Settings.self) private var settings
    @State private var filter = Filter.all
    @State private var editing: PluginDraft?
    @State private var renaming: Plugin?
    @State private var renameText = ""
    @State private var importsFile = false
    @State private var importsLink = false
    @State private var showsAddOptions = false
    @State private var problem: String?

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case enabled
        case mine

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .all: "All"
            case .enabled: "Enabled"
            case .mine: "Mine"
            }
        }
    }

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                Button {
                    showsAddOptions = true
                } label: {
                    Label("Add Plugin", systemImage: "plus.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            Section {
                Picker("Show", selection: $filter) {
                    ForEach(Filter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            ForEach(PluginCategory.allCases) { category in
                let rows = visible.filter { $0.category == category }
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { plugin in
                            row(plugin)
                        }
                    } header: {
                        Text(category.title)
                    }
                }
            }

            if visible.isEmpty {
                ContentUnavailableView(
                    "No Plugins",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Add a script or a style to see it here.")
                )
                .listRowBackground(Color.clear)
            }

            Section {
                Link(destination: PluginDocs.url) {
                    Label("Documentation", systemImage: "book.closed")
                }
                Toggle(isOn: $settings.webInspector) {
                    Label("Web Inspector", systemImage: "ladybug")
                }
            } header: {
                Text("For Developers")
            } footer: {
                Text("Plugins use the Skrrt API described in the documentation. Turn on Web Inspector to debug pages from Safari on a Mac.")
            }
        }
        .navigationTitle("Plugins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsAddOptions = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("Add Plugin"))
            }
        }
        .confirmationDialog("Add Plugin", isPresented: $showsAddOptions, titleVisibility: .visible) {
            Button("Import from Files") { importsFile = true }
            Button("Import from Link") { importsLink = true }
            Button("New Script") { editing = PluginDraft(existing: nil, kind: .script) }
            Button("New Style") { editing = PluginDraft(existing: nil, kind: .style) }
        }
        .fileImporter(isPresented: $importsFile, allowedContentTypes: importTypes, allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        try store.importFile(url)
                    } catch {
                        problem = String(localized: "Could not read the file.")
                    }
                }
            case .failure:
                problem = String(localized: "Could not read the file.")
            }
        }
        .sheet(item: $editing) { draft in
            PluginEditor(draft: draft)
        }
        .sheet(isPresented: $importsLink) {
            ImportLinkSheet()
        }
        .alert("Rename", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let plugin = renaming {
                    store.rename(plugin.id, to: renameText)
                }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .alert("Plugins", isPresented: Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: problem ?? "")
        }
    }

    private var importTypes: [UTType] {
        [UTType.javaScript, UTType(filenameExtension: "js"), UTType(filenameExtension: "css"), UTType.plainText, UTType.text]
            .compactMap { $0 }
    }

    private var visible: [Plugin] {
        switch filter {
        case .all: store.items
        case .enabled: store.items.filter(\.isEnabled)
        case .mine: store.items.filter { !$0.isBuiltIn }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(store.enabledCount) of \(store.items.count) enabled")
                    .font(.headline)
                Text("Scripts and styles that change how websites look and work.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func row(_ plugin: Plugin) -> some View {
        HStack(spacing: 12) {
            SettingsIcon(symbol: plugin.icon, color: plugin.category.color)
            VStack(alignment: .leading, spacing: 2) {
                name(plugin)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                summary(plugin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                scope(plugin)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(plugin.category.color)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { store.plugin(plugin.id)?.isEnabled ?? false },
                set: { store.setEnabled(plugin.id, $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
        .contextMenu {
            if !plugin.isBuiltIn {
                Button("Edit", systemImage: "pencil") {
                    editing = PluginDraft(existing: plugin, kind: plugin.kind)
                }
                Button("Rename", systemImage: "character.cursor.ibeam") {
                    renameText = plugin.name
                    renaming = plugin
                }
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                store.duplicate(plugin.id)
            }
            ShareLink(item: plugin.exportSource, subject: Text(verbatim: plugin.name)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            if !plugin.isBuiltIn {
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    withAnimation { store.remove(plugin.id) }
                }
            }
        }
        .swipeActions(edge: .trailing) {
            if !plugin.isBuiltIn {
                Button("Delete", role: .destructive) {
                    withAnimation { store.remove(plugin.id) }
                }
                Button("Rename") {
                    renameText = plugin.name
                    renaming = plugin
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .leading) {
            if !plugin.isBuiltIn {
                Button("Edit") {
                    editing = PluginDraft(existing: plugin, kind: plugin.kind)
                }
                .tint(.blue)
            } else {
                Button("Duplicate") {
                    store.duplicate(plugin.id)
                }
                .tint(.blue)
            }
        }
    }

    private func name(_ plugin: Plugin) -> Text {
        plugin.isBuiltIn ? Text(LocalizedStringKey(plugin.name)) : Text(verbatim: plugin.name)
    }

    private func summary(_ plugin: Plugin) -> Text {
        if plugin.summary.isEmpty { return Text(verbatim: "") }
        return plugin.isBuiltIn ? Text(LocalizedStringKey(plugin.summary)) : Text(verbatim: plugin.summary)
    }

    private func scope(_ plugin: Plugin) -> Text {
        plugin.matches.isEmpty ? Text("All sites") : Text(verbatim: plugin.matches.joined(separator: ", "))
    }
}

struct PluginDraft: Identifiable {
    let id = UUID()
    var existing: Plugin?
    var kind: Plugin.Kind
}

struct PluginEditor: View {
    let draft: PluginDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(PluginStore.self) private var store
    @State private var name = ""
    @State private var summary = ""
    @State private var icon = "curlybraces"
    @State private var kind = Plugin.Kind.script
    @State private var sites = ""
    @State private var excluded = ""
    @State private var runsAtStart = false
    @State private var code = ""

    private let icons = [
        "curlybraces", "paintbrush.fill", "sparkles", "bolt.fill", "wand.and.stars", "star.fill", "flame.fill",
        "leaf.fill", "moon.fill", "sun.max.fill", "eye.slash.fill", "lock.fill", "globe", "play.rectangle.fill",
        "text.alignleft", "hand.tap.fill", "gearshape.fill", "heart.fill", "bell.fill", "scissors"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $summary)
                    Picker("Type", selection: $kind) {
                        Text("Script").tag(Plugin.Kind.script)
                        Text("Style").tag(Plugin.Kind.style)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(icons, id: \.self) { symbol in
                                Button {
                                    icon = symbol
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(icon == symbol ? Color.white : Color.primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            icon == symbol ? Color.accentColor : Color.primary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Icon")
                }
                Section {
                    TextField("example.com", text: $sites, axis: .vertical)
                        .lineLimit(1...4)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Exclude, one per line", text: $excluded, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if kind == .script {
                        Toggle("Run Before the Page Loads", isOn: $runsAtStart)
                    }
                } header: {
                    Text("Websites")
                } footer: {
                    Text("One address per line. Leave empty to run on every site. Wildcards like *.example.com work.")
                }
                Section {
                    TextEditor(text: $code)
                        .font(.system(size: 14, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(minHeight: 240)
                } header: {
                    Text("Code")
                }
            }
            .navigationTitle(draft.existing == nil ? "New Plugin" : "Edit Plugin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func lines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func load() {
        if let existing = draft.existing {
            name = existing.name
            summary = existing.summary
            icon = existing.icon
            kind = existing.kind
            sites = existing.matches.joined(separator: "\n")
            excluded = existing.excludes.joined(separator: "\n")
            runsAtStart = existing.runsAtStart
            code = existing.code
        } else {
            kind = draft.kind
            icon = draft.kind == .style ? "paintbrush.fill" : "curlybraces"
            code = draft.kind == .style
                ? "/* Write CSS here. It is applied to every page that matches. */\nbody {\n  \n}\n"
                : "// Skrrt API is available as the global `Skrrt`.\nSkrrt.toast('Hello from ' + Skrrt.host);\n"
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if var existing = draft.existing {
            existing.name = cleanName
            existing.summary = summary
            existing.icon = icon
            existing.kind = kind
            existing.matches = lines(sites)
            existing.excludes = lines(excluded)
            existing.runsAtStart = runsAtStart
            existing.code = code
            store.update(existing)
        } else {
            store.add(Plugin(
                id: UUID().uuidString,
                name: cleanName,
                summary: summary,
                icon: icon,
                category: .mine,
                kind: kind,
                matches: lines(sites),
                excludes: lines(excluded),
                runsAtStart: runsAtStart,
                version: "1.0",
                code: code,
                isEnabled: true,
                isBuiltIn: false
            ))
        }
        dismiss()
    }
}

struct ImportLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PluginStore.self) private var store
    @State private var address = ""
    @State private var isLoading = false
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/plugin.js", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if failed {
                        Text("Could not download the plugin. Check the link.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Paste a link to a .js or .css file. Only import plugins you trust.")
                    }
                }
            }
            .navigationTitle("Import from Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Import") { run() }
                            .disabled(URL(string: address.trimmingCharacters(in: .whitespaces)) == nil || address.isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func run() {
        guard let url = URL(string: address.trimmingCharacters(in: .whitespaces)), url.scheme?.hasPrefix("http") == true else {
            failed = true
            return
        }
        isLoading = true
        failed = false
        Task {
            do {
                try await store.importLink(url)
                dismiss()
            } catch {
                failed = true
            }
            isLoading = false
        }
    }
}
