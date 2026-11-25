import SwiftUI

struct PluginDraft: Identifiable {
    let id = UUID()
    var existing: Plugin?
    var kind: Plugin.Kind
}

/// The editor for plugins you write yourself. Most people never need it: the store has ready plugins.
struct PluginEditor: View {
    let draft: PluginDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(PluginStore.self) private var store
    @State private var name = ""
    @State private var summary = ""
    @State private var icon = "curlybraces"
    @State private var colorHex = "#32ADE6"
    @State private var emoji: Int?
    @State private var devLogo: Int?
    @State private var logoKind = LogoKind.symbol

    private enum LogoKind: String, CaseIterable, Identifiable {
        case symbol
        case emoji
        case dev

        var id: String { rawValue }
    }
    @State private var kind = Plugin.Kind.script
    @State private var sites = ""
    @State private var excluded = ""
    @State private var runsAtStart = false
    @State private var inPage = false
    @State private var code = ""

    private let icons = [
        "curlybraces", "paintbrush.fill", "sparkles", "bolt.fill", "wand.and.stars", "star.fill", "flame.fill",
        "leaf.fill", "moon.fill", "sun.max.fill", "eye.slash.fill", "lock.fill", "globe", "play.rectangle.fill",
        "text.alignleft", "hand.tap.fill", "gearshape.fill", "heart.fill", "bell.fill", "scissors"
    ]

    private let colors = ["#0A84FF", "#32ADE6", "#34C759", "#FF9F0A", "#FF453A", "#FF375F", "#BF5AF2", "#5E5CE6", "#8E8E93"]

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(icons, id: \.self) { symbol in
                        Button {
                            icon = symbol
                            emoji = nil
                            devLogo = nil
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(icon == symbol && emoji == nil && devLogo == nil ? Color.white : Color.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    icon == symbol && emoji == nil && devLogo == nil ? Color.accentColor : Color.primary.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors, id: \.self) { hex in
                        Button {
                            colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var emojiGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(0..<EmojiLibrary.count, id: \.self) { index in
                    Button {
                        emoji = index
                        devLogo = nil
                    } label: {
                        AnimatedEmoji(index: index, animated: false)
                            .frame(width: 44, height: 44)
                            .padding(4)
                            .background(
                                emoji == index ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay {
                                if emoji == index {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 260)
    }

    private var devLogoGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(0..<EmojiLibrary.devLogoCount, id: \.self) { index in
                    Button {
                        devLogo = index
                        emoji = nil
                    } label: {
                        Group {
                            if let image = EmojiLibrary.devLogo(index) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: 44, height: 44)
                        .padding(4)
                        .background(
                            devLogo == index ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            if devLogo == index {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 260)
    }


    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        PluginIconView(icon: PluginIcon(symbol: icon, color: colorHex, logoHost: nil, emoji: emoji, devLogo: devLogo), size: 56)
                        VStack(spacing: 8) {
                            TextField("Name", text: $name)
                            TextField("Description (optional)", text: $summary)
                        }
                    }
                    Picker("Type", selection: $kind) {
                        Text("Script").tag(Plugin.Kind.script)
                        Text("Style").tag(Plugin.Kind.style)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Picker("Logo", selection: $logoKind) {
                        Text("Symbol").tag(LogoKind.symbol)
                        Text("Emoji").tag(LogoKind.emoji)
                        Text("Logos").tag(LogoKind.dev)
                    }
                    .pickerStyle(.segmented)
                    switch logoKind {
                    case .symbol:
                        symbolPicker
                    case .emoji:
                        emojiGrid
                    case .dev:
                        devLogoGrid
                    }
                } header: {
                    Text("Logo")
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
                        Toggle("Access Page Variables", isOn: $inPage)
                    }
                } header: {
                    Text("Websites")
                } footer: {
                    Text("One address per line. Leave empty to run on every site. Wildcards like *.example.com work. Page variables are off by default for safety.")
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
            name = existing.name.text("en")
            summary = existing.summary.text("en")
            icon = existing.icon.symbol
            colorHex = existing.icon.color
            emoji = existing.icon.emoji
            devLogo = existing.icon.devLogo
            logoKind = existing.icon.emoji != nil ? .emoji : (existing.icon.devLogo != nil ? .dev : .symbol)
            kind = existing.kind
            sites = existing.matches.joined(separator: "\n")
            excluded = existing.excludes.joined(separator: "\n")
            runsAtStart = existing.runsAtStart
            inPage = existing.inPage
            code = existing.code
        } else {
            kind = draft.kind
            icon = draft.kind == .style ? "paintbrush.fill" : "curlybraces"
            code = draft.kind == .style
                ? "/* Write CSS here. It is applied to every page that matches. */\nbody {\n  \n}\n"
                : "// Skrrt API is available as the global `Skrrt`.\nSkrrt.toast('Hello from ' + Skrrt.host, 5000);\n"
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let plugin = Plugin(
            id: draft.existing?.id ?? UUID().uuidString,
            name: L10n(cleanName),
            summary: L10n(summary),
            details: L10n(summary),
            icon: PluginIcon(symbol: icon, color: colorHex, logoHost: nil, emoji: emoji, devLogo: devLogo),
            category: .mine,
            kind: kind,
            matches: lines(sites),
            excludes: lines(excluded),
            runsAtStart: runsAtStart,
            inPage: inPage && kind == .script,
            version: draft.existing?.version ?? "1.0",
            author: "",
            code: code,
            permissions: draft.existing?.permissions ?? PluginPermissions(),
            options: draft.existing?.options ?? [],
            values: draft.existing?.values ?? [:],
            blockedHosts: draft.existing?.blockedHosts ?? [],
            isEnabled: draft.existing?.isEnabled ?? true,
            storeID: nil
        )
        if draft.existing != nil {
            store.update(plugin)
        } else {
            store.add(plugin)
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
