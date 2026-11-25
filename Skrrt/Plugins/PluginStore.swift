import Observation
import SwiftUI
import WebKit

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
        items.filter { !$0.isBuiltIn }
    }

    func makeScripts() -> [WKUserScript] {
        PluginRuntime.scripts(for: items)
    }

    func plugin(_ id: String) -> Plugin? {
        items.first { $0.id == id }
    }

    func setEnabled(_ id: String, _ value: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isEnabled = value
        persist()
    }

    func rename(_ id: String, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let index = items.firstIndex(where: { $0.id == id }), !items[index].isBuiltIn else { return }
        items[index].name = clean
        persist()
    }

    func update(_ plugin: Plugin) {
        guard let index = items.firstIndex(where: { $0.id == plugin.id }), !items[index].isBuiltIn else { return }
        items[index] = plugin
        persist()
    }

    func remove(_ id: String) {
        guard let plugin = plugin(id), !plugin.isBuiltIn else { return }
        items.removeAll { $0.id == id }
        persist()
    }

    /// Copies any plugin, including a built-in one, into "My Plugins" so it can be edited.
    @discardableResult
    func duplicate(_ id: String) -> Plugin? {
        guard var copy = plugin(id) else { return nil }
        copy.id = UUID().uuidString
        copy.name = copy.isBuiltIn ? String(localized: "\(copy.name) copy") : copy.name + " 2"
        copy.category = .mine
        copy.isBuiltIn = false
        copy.isEnabled = false
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
        return Plugin(
            id: UUID().uuidString,
            name: meta.name ?? (base.isEmpty ? String(localized: "New Plugin") : base),
            summary: meta.summary ?? "",
            icon: meta.icon ?? (isStyle ? "paintbrush.fill" : "curlybraces"),
            category: .mine,
            kind: isStyle ? .style : .script,
            matches: meta.matches,
            excludes: meta.excludes,
            runsAtStart: meta.runsAtStart,
            version: meta.version ?? "1.0",
            code: source,
            isEnabled: true,
            isBuiltIn: false
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
        let text = String(decoding: data, as: UTF8.self)
        return importSource(text, fileName: url.lastPathComponent)
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

    private struct Saved: Codable {
        var user: [Plugin]
        var enabled: [String: Bool]
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("plugins.json")
    }

    private func load() {
        var saved = Saved(user: [], enabled: [:])
        if let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = decoded
        } else if let legacy = Self.legacyEnabledFlags() {
            saved.enabled = legacy
        }
        var merged = BuiltInPlugins.all.map { builtIn -> Plugin in
            var copy = builtIn
            if let flag = saved.enabled[builtIn.id] {
                copy.isEnabled = flag
            }
            return copy
        }
        merged += saved.user
        items = merged
    }

    /// Keeps the on/off state of the three plugins that existed as extensions in earlier versions.
    private static func legacyEnabledFlags() -> [String: Bool]? {
        struct Old: Decodable {
            var id: String
            var isEnabled: Bool
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        guard let data = try? Data(contentsOf: base.appendingPathComponent("extensions.json")),
              let old = try? JSONDecoder().decode([Old].self, from: data) else { return nil }
        return Dictionary(old.map { ($0.id, $0.isEnabled) }, uniquingKeysWith: { first, _ in first })
    }

    private func persist() {
        let saved = Saved(
            user: items.filter { !$0.isBuiltIn },
            enabled: Dictionary(uniqueKeysWithValues: items.filter(\.isBuiltIn).map { ($0.id, $0.isEnabled) })
        )
        if let data = try? JSONEncoder().encode(saved) {
            try? data.write(to: fileURL, options: .atomic)
        }
        onChange?()
    }
}
