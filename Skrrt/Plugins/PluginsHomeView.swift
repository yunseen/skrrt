import SwiftUI
import UniformTypeIdentifiers

/// The plugins screen: the store on one side, what you installed on the other.
struct PluginsHomeView: View {
    @Environment(PluginStore.self) private var store
    @Environment(PluginCatalog.self) private var catalog
    @Environment(Settings.self) private var settings
    @State private var page = Page.store
    @State private var query = ""
    @State private var category: PluginCategory?
    @State private var editing: PluginDraft?
    @State private var importsFile = false
    @State private var importsLink = false
    @State private var problem: String?

    enum Page: String, CaseIterable, Identifiable {
        case store
        case installed

        var id: String { rawValue }
    }

    private var language: String { settings.languageCode }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Plugins", selection: $page) {
                Text("Store").tag(Page.store)
                Text("Installed \(store.items.count)").tag(Page.installed)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch page {
            case .store:
                storeList
            case .installed:
                installedList
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Plugins")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search plugins"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Add your own") {
                        Button("Import from Files", systemImage: "folder") { importsFile = true }
                        Button("Import from Link", systemImage: "link") { importsLink = true }
                        Button("New Script", systemImage: "curlybraces") { editing = PluginDraft(existing: nil, kind: .script) }
                        Button("New Style", systemImage: "paintbrush") { editing = PluginDraft(existing: nil, kind: .style) }
                    }
                    Link(destination: PluginDocs.url) {
                        Label("Documentation", systemImage: "book.closed")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("Add Plugin"))
            }
        }
        .task { await catalog.refresh() }
        .fileImporter(isPresented: $importsFile, allowedContentTypes: importTypes, allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        try store.importFile(url)
                        page = .installed
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

    // MARK: Store

    private var filteredEntries: [StoreEntry] {
        catalog.entries.filter { entry in
            if let category, entry.category != category { return false }
            if query.isEmpty { return true }
            let text = entry.name.text(language) + " " + entry.summary.text(language)
            return text.localizedCaseInsensitiveContains(query)
        }
    }

    private var storeList: some View {
        List {
            if query.isEmpty && category == nil && !featuredEntries.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(featuredEntries) { entry in
                                NavigationLink {
                                    PluginDetailView(entry: entry)
                                } label: {
                                    FeaturedCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Featured")
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(nil)
                        ForEach(categoriesInStore) { item in
                            chip(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(filteredEntries) { entry in
                    NavigationLink {
                        PluginDetailView(entry: entry)
                    } label: {
                        StoreRow(entry: entry)
                    }
                }
                if filteredEntries.isEmpty {
                    if catalog.state == .loading && catalog.entries.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ContentUnavailableView.search(text: query)
                            .listRowBackground(Color.clear)
                    }
                }
            } header: {
                Text(category?.title ?? "All Plugins")
            } footer: {
                if catalog.state == .offline {
                    Text("You are offline. The plugins that came with the app are shown.")
                }
            }
        }
        .refreshable { await catalog.refresh(force: true) }
    }

    private var featuredEntries: [StoreEntry] {
        catalog.entries.filter(\.featured)
    }

    private var categoriesInStore: [PluginCategory] {
        PluginCategory.allCases.filter { item in catalog.entries.contains { $0.category == item } }
    }

    private func chip(_ item: PluginCategory?) -> some View {
        Button {
            category = item
        } label: {
            HStack(spacing: 6) {
                if let item {
                    Image(systemName: item.symbol).font(.system(size: 12, weight: .semibold))
                    Text(item.title)
                } else {
                    Text("All")
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(category == item ? Color.white : Color.primary)
            .background(category == item ? Color.accentColor : Color.primary.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Installed

    private var updates: [Plugin] {
        store.items.filter { catalog.hasUpdate(for: $0) }
    }

    private var installed: [Plugin] {
        store.items.filter { plugin in
            query.isEmpty || plugin.name.text(language).localizedCaseInsensitiveContains(query)
        }
    }

    private var installedList: some View {
        List {
            if store.items.isEmpty {
                ContentUnavailableView {
                    Label("No Plugins Installed", systemImage: "puzzlepiece.extension")
                } description: {
                    Text("Get plugins from the store. They work in every tab.")
                } actions: {
                    Button("Open the Store") { page = .store }
                        .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                if !updates.isEmpty && query.isEmpty {
                    Section {
                        ForEach(updates) { plugin in
                            NavigationLink {
                                PluginDetailView(pluginID: plugin.id)
                            } label: {
                                HStack(spacing: 12) {
                                    PluginIconView(icon: plugin.icon, size: 40)
                                    Text(verbatim: plugin.name.text(language))
                                    Spacer()
                                    if let entry = catalog.entry(plugin.storeID ?? "") {
                                        GetButton(entry: entry)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Updates")
                    }
                }
                ForEach(PluginCategory.allCases) { group in
                    let rows = installed.filter { $0.category == group }
                    if !rows.isEmpty {
                        Section {
                            ForEach(rows) { plugin in
                                NavigationLink {
                                    PluginDetailView(pluginID: plugin.id)
                                } label: {
                                    InstalledRow(plugin: plugin)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Remove", role: .destructive) {
                                        withAnimation { store.uninstall(plugin.id) }
                                    }
                                }
                            }
                        } header: {
                            Text(group.title)
                        }
                    }
                }
            }
        }
    }
}

struct InstalledRow: View {
    let plugin: Plugin

    @Environment(PluginStore.self) private var store
    @Environment(Settings.self) private var settings

    var body: some View {
        HStack(spacing: 12) {
            PluginIconView(icon: plugin.icon, size: 44)
                .opacity(plugin.isEnabled ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: plugin.name.text(settings.languageCode))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text(verbatim: plugin.summary.text(settings.languageCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if !plugin.blockedHosts.isEmpty {
                    Text("Off on \(plugin.blockedHosts.count) sites")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { store.plugin(plugin.id)?.isEnabled ?? false },
                set: { store.setEnabled(plugin.id, $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

struct StoreRow: View {
    let entry: StoreEntry

    @Environment(Settings.self) private var settings

    var body: some View {
        HStack(spacing: 12) {
            PluginIconView(icon: entry.icon, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: entry.name.text(settings.languageCode))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text(verbatim: entry.summary.text(settings.languageCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(entry.category.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.category.color)
            }
            Spacer(minLength: 8)
            GetButton(entry: entry)
        }
        .padding(.vertical, 3)
    }
}

struct FeaturedCard: View {
    let entry: StoreEntry

    @Environment(Settings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PluginIconView(icon: entry.icon, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: entry.name.text(settings.languageCode))
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                Text(verbatim: entry.summary.text(settings.languageCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            GetButton(entry: entry)
        }
        .padding(14)
        .frame(width: 170, height: 190, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// The blue "Get" pill of the store. It turns into a spinner while downloading and into "Installed" afterwards.
struct GetButton: View {
    let entry: StoreEntry

    @Environment(PluginStore.self) private var store
    @Environment(PluginCatalog.self) private var catalog
    @State private var problem: String?

    var body: some View {
        Group {
            if catalog.installing.contains(entry.id) {
                ProgressView()
                    .frame(width: 70, height: 30)
            } else if let installed = store.installed(storeID: entry.id) {
                if catalog.hasUpdate(for: installed) {
                    pill("Update", filled: true) { install() }
                } else {
                    pill("Installed", filled: false) {}
                        .allowsHitTesting(false)
                }
            } else {
                pill("Get", filled: true) { install() }
            }
        }
        .alert("Plugins", isPresented: Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: problem ?? "")
        }
    }

    private func pill(_ title: LocalizedStringKey, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(filled ? Color.white : Color.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(filled ? Color.accentColor : Color.primary.opacity(0.08), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.borderless)
    }

    private func install() {
        Task {
            do {
                try await catalog.install(entry, into: store)
            } catch {
                problem = error.localizedDescription
            }
        }
    }
}
