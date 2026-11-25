import Observation
import SwiftUI

struct StoreEntry: Codable, Identifiable, Equatable {
    var id: String
    var version: String
    var category: PluginCategory
    var kind: Plugin.Kind
    var name: L10n
    var summary: L10n
    var icon: PluginIcon
    var author: String
    var featured: Bool
    var path: String
}

private struct StoreIndex: Codable {
    var plugins: [StoreEntry]
}

enum StoreError: LocalizedError {
    case unavailable
    case broken

    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: "The plugin could not be downloaded. Check your connection and try again.")
        case .broken: String(localized: "The plugin file is damaged.")
        }
    }
}

/// The plugin store. The list and the plugin files are downloaded from the Skrrt repository on GitHub,
/// so new plugins appear without an app update. A copy shipped inside the app is used when you are offline.
@MainActor
@Observable
final class PluginCatalog {
    enum State {
        case loading
        case ready
        case offline
    }

    private(set) var entries: [StoreEntry] = []
    private(set) var state = State.loading
    private(set) var installing: Set<String> = []

    @ObservationIgnored private let remoteBase = URL(string: "https://raw.githubusercontent.com/yunseen/skrrt/main/Store/")!
    @ObservationIgnored private var didLoad = false

    init() {
        entries = Self.bundledIndex()?.plugins ?? []
    }

    func refresh(force: Bool = false) async {
        if didLoad && !force { return }
        didLoad = true
        state = .loading
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteBase.appendingPathComponent("index.json"))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw StoreError.unavailable }
            let index = try JSONDecoder().decode(StoreIndex.self, from: data)
            if !index.plugins.isEmpty {
                entries = index.plugins
                state = .ready
                return
            }
        } catch {}
        state = entries.isEmpty ? .offline : .ready
    }

    func entry(_ id: String) -> StoreEntry? {
        entries.first { $0.id == id }
    }

    /// True when the store has a newer version than the installed one.
    func hasUpdate(for installed: Plugin) -> Bool {
        guard let storeID = installed.storeID, let entry = entry(storeID) else { return false }
        return Self.isNewer(entry.version, than: installed.version)
    }

    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0
            let y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    /// Downloads a plugin and installs it. Falls back to the copy inside the app when the network fails.
    func install(_ entry: StoreEntry, into store: PluginStore) async throws {
        installing.insert(entry.id)
        defer { installing.remove(entry.id) }
        let plugin: Plugin
        do {
            plugin = try await download(entry)
        } catch {
            guard let local = Self.bundledPlugin(entry) else { throw StoreError.unavailable }
            plugin = local
        }
        store.install(plugin)
    }

    func previewDownload(_ entry: StoreEntry) async throws -> Plugin {
        try await download(entry)
    }

    private func download(_ entry: StoreEntry) async throws -> Plugin {
        let folder = remoteBase.appendingPathComponent(entry.path, isDirectory: true)
        let (manifestData, manifestResponse) = try await URLSession.shared.data(from: folder.appendingPathComponent("manifest.json"))
        guard (manifestResponse as? HTTPURLResponse)?.statusCode == 200 else { throw StoreError.unavailable }
        guard let manifest = try? JSONDecoder().decode(PluginManifest.self, from: manifestData) else { throw StoreError.broken }
        let (codeData, codeResponse) = try await URLSession.shared.data(from: folder.appendingPathComponent(manifest.file))
        guard (codeResponse as? HTTPURLResponse)?.statusCode == 200 else { throw StoreError.unavailable }
        let code = String(decoding: codeData, as: UTF8.self)
        guard !code.isEmpty else { throw StoreError.broken }
        return manifest.makePlugin(code: code)
    }

    // MARK: Copy inside the app

    private static var bundledRoot: URL? {
        Bundle.main.url(forResource: "Store", withExtension: nil)
    }

    private static func bundledIndex() -> StoreIndex? {
        guard let root = bundledRoot,
              let data = try? Data(contentsOf: root.appendingPathComponent("index.json")) else { return nil }
        return try? JSONDecoder().decode(StoreIndex.self, from: data)
    }

    static func previewBundled(_ entry: StoreEntry) -> Plugin? {
        bundledPlugin(entry)
    }

    private static func bundledPlugin(_ entry: StoreEntry) -> Plugin? {
        guard let root = bundledRoot else { return nil }
        let folder = root.appendingPathComponent(entry.path, isDirectory: true)
        guard let manifestData = try? Data(contentsOf: folder.appendingPathComponent("manifest.json")),
              let manifest = try? JSONDecoder().decode(PluginManifest.self, from: manifestData),
              let codeData = try? Data(contentsOf: folder.appendingPathComponent(manifest.file)) else { return nil }
        return manifest.makePlugin(code: String(decoding: codeData, as: UTF8.self))
    }
}

extension PluginCatalog {
    /// Downloads a plugin without installing it, to show its description, settings and permissions.
    func preview(_ entry: StoreEntry) async -> Plugin? {
        if let plugin = try? await previewDownload(entry) { return plugin }
        return Self.previewBundled(entry)
    }
}
