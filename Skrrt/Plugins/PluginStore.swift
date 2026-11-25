import Observation
import SwiftUI
import WebKit

/// The plugins installed on this device: their switches, settings and per-site exceptions.
@MainActor
@Observable
final class PluginStore {
    private(set) var items: [Plugin] = []
    @ObservationIgnored var onChange: (@MainActor () -> Void)?

    init() {
        load()
    }

    var enabledCount: Int {
        items.filter(\.isEnabled).count
    }

    var userPlugins: [Plugin] {
        items.filter(\.isUser)
    }

    func plugin(_ id: String) -> Plugin? {
        items.first { $0.id == id }
    }

    func isInstalled(storeID: String) -> Bool {
        items.contains { $0.storeID == storeID }
    }

    func installed(storeID: String) -> Plugin? {
        items.first { $0.storeID == storeID }
    }

    /// Plugins that would run on this site, for the site menu.
    func plugins(for host: String) -> [Plugin] {
        items.filter { $0.applies(to: host) }
    }

    // MARK: Install and remove

    /// Adds a plugin from the store, or replaces it with a newer version and keeps its settings.
    func install(_ plugin: Plugin) {
        if let index = items.firstIndex(where: { $0.storeID == plugin.storeID && plugin.storeID != nil }) {
            var updated = plugin
            updated.values = items[index].values
            updated.blockedHosts = items[index].blockedHosts
            updated.isEnabled = items[index].isEnabled
            items[index] = updated
        } else {
            items.append(plugin)
        }
        persist()
    }

    func uninstall(_ id: String) {
        items.removeAll { $0.id == id }
        persist()
    }

    // MARK: Switches and settings

    func setEnabled(_ id: String, _ value: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isEnabled = value
        persist()
    }

    func setValue(_ id: String, key: String, _ value: OptionValue) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].values[key] = value
        persist()
    }

    func resetValues(_ id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].values = [:]
        persist()
    }

    /// Turns a plugin on or off for one site only, like the per-site switch of Chrome extensions.
    func setActive(_ id: String, on host: String, _ value: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let clean = host.lowercased().replacingOccurrences(of: "www.", with: "")
        if value {
            items[index].blockedHosts.removeAll { $0 == clean }
            if !items[index].isEnabled { items[index].isEnabled = true }
        } else if !items[index].blockedHosts.contains(clean) {
            items[index].blockedHosts.append(clean)
        }
        persist()
    }

    func unblock(_ id: String, host: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].blockedHosts.removeAll { $0 == host }
        persist()
    }

    // MARK: Your own plugins

    func rename(_ id: String, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let index = items.firstIndex(where: { $0.id == id }), items[index].isUser else { return }
        items[index].name = L10n(clean)
        persist()
    }

    func update(_ plugin: Plugin) {
        guard let index = items.firstIndex(where: { $0.id == plugin.id }), items[index].isUser else { return }
        items[index] = plugin
        persist()
    }

    /// Copies any plugin into "My Plugins" so it can be edited.
    @discardableResult
    func duplicate(_ id: String) -> Plugin? {
        guard var copy = plugin(id) else { return nil }
        copy.id = UUID().uuidString
        copy.storeID = nil
        copy.category = .mine
        copy.isEnabled = false
        copy.name = L10n(copy.name.text("en") + " 2")
        items.append(copy)
        persist()
        return copy
    }

    @discardableResult
    func add(_ plugin: Plugin) -> Plugin {
        items.append(plugin)
        persist()
        return plugin
    }

    /// Builds a plugin from the text of a `.js` or `.css` file, reading its optional header.
    func makePlugin(source: String, fileName: String) -> Plugin {
        let meta = PluginMeta.parse(source)
        let ext = (fileName as NSString).pathExtension.lowercased()
        let base = (fileName as NSString).deletingPathExtension
        let isStyle = ext == "css"
        let title = meta.name ?? (base.isEmpty ? "New Plugin" : base)
        return Plugin(
            id: UUID().uuidString,
            name: L10n(title),
            summary: L10n(meta.summary ?? ""),
            details: L10n(meta.summary ?? ""),
            icon: PluginIcon(symbol: meta.icon ?? (isStyle ? "paintbrush.fill" : "curlybraces"), color: "#32ADE6", logoHost: nil),
            category: .mine,
            kind: isStyle ? .style : .script,
            matches: meta.matches,
            excludes: meta.excludes,
            runsAtStart: meta.runsAtStart,
            inPage: false,
            version: meta.version ?? "1.0",
            author: "",
            code: source,
            permissions: PluginPermissions(),
            options: [],
            values: [:],
            blockedHosts: [],
            isEnabled: true,
            storeID: nil
        )
    }

    @discardableResult
    func importSource(_ source: String, fileName: String) -> Plugin {
        add(makePlugin(source: source, fileName: fileName))
    }

    @discardableResult
    func importFile(_ url: URL) throws -> Plugin {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        return importSource(String(decoding: data, as: UTF8.self), fileName: url.lastPathComponent)
    }

    @discardableResult
    func importLink(_ url: URL) async throws -> Plugin {
        let (data, _) = try await URLSession.shared.data(from: url)
        let text = String(decoding: data, as: UTF8.self)
        guard !text.isEmpty else { throw URLError(.zeroByteResource) }
        let name = url.lastPathComponent.isEmpty ? "plugin.js" : url.lastPathComponent
        return importSource(text, fileName: name)
    }

    // MARK: Storage

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("installed-plugins.json")
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode([Plugin].self, from: data) {
            items = decoded
            return
        }
        items = Self.migrateLegacyPlugins()
    }

    /// Earlier versions kept your own plugins in `plugins.json`. The built-in ones are gone: they live in the store now.
    private static func migrateLegacyPlugins() -> [Plugin] {
        struct Old: Decodable {
            var id: String
            var name: String
            var summary: String
            var icon: String
            var kind: Plugin.Kind
            var matches: [String]
            var excludes: [String]
            var runsAtStart: Bool
            var version: String
            var code: String
            var isEnabled: Bool
            var isBuiltIn: Bool
        }
        struct Saved: Decodable {
            var user: [Old]
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        guard let data = try? Data(contentsOf: base.appendingPathComponent("plugins.json")),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return [] }
        return saved.user.filter { !$0.isBuiltIn }.map { old in
            Plugin(
                id: old.id,
                name: L10n(old.name),
                summary: L10n(old.summary),
                details: L10n(old.summary),
                icon: PluginIcon(symbol: old.icon, color: "#32ADE6", logoHost: nil),
                category: .mine,
                kind: old.kind,
                matches: old.matches,
                excludes: old.excludes,
                runsAtStart: old.runsAtStart,
                inPage: false,
                version: old.version,
                author: "",
                code: old.code,
                permissions: PluginPermissions(),
                options: [],
                values: [:],
                blockedHosts: [],
                isEnabled: old.isEnabled,
                storeID: nil
            )
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL, options: .atomic)
        }
        onChange?()
    }
}
