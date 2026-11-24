import Observation
import SwiftUI
import UIKit

struct Shortcut: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var urlString: String
    var asset: String?
    var hasIcon = false

    var url: URL? {
        URL(string: urlString)
    }
}

@MainActor
@Observable
final class ShortcutStore {
    private(set) var items: [Shortcut] = []

    @ObservationIgnored private var images: [UUID: UIImage] = [:]
    @ObservationIgnored private let fileManager = FileManager.default

    init() {
        load()
    }

    func icon(for shortcut: Shortcut) -> UIImage? {
        guard shortcut.hasIcon else { return nil }
        if let cached = images[shortcut.id] { return cached }
        guard let data = try? Data(contentsOf: iconURL(shortcut.id)), let image = UIImage(data: data) else { return nil }
        images[shortcut.id] = image
        return image
    }

    @discardableResult
    func add(title: String, url: URL, icon: UIImage?) -> Shortcut {
        var shortcut = Shortcut(title: title, urlString: url.absoluteString)
        if let icon, save(icon, id: shortcut.id) {
            shortcut.hasIcon = true
            images[shortcut.id] = icon
        }
        items.append(shortcut)
        persist()
        return shortcut
    }

    func update(_ shortcut: Shortcut, title: String, url: URL, icon: UIImage?) {
        guard let index = items.firstIndex(where: { $0.id == shortcut.id }) else { return }
        var updated = items[index]
        updated.title = title
        updated.urlString = url.absoluteString
        if let icon, save(icon, id: updated.id) {
            updated.hasIcon = true
            updated.asset = nil
            images[updated.id] = icon
        }
        items[index] = updated
        persist()
    }

    func remove(_ shortcut: Shortcut) {
        items.removeAll { $0.id == shortcut.id }
        images[shortcut.id] = nil
        try? fileManager.removeItem(at: iconURL(shortcut.id))
        persist()
    }

    func resetToDefaults() {
        for item in items {
            try? fileManager.removeItem(at: iconURL(item.id))
        }
        images.removeAll()
        items = Self.defaults
        persist()
    }

    private static let defaults: [Shortcut] = [
        Shortcut(title: "Google", urlString: "https://www.google.com", asset: "FaviconGoogle"),
        Shortcut(title: "YouTube", urlString: "https://www.youtube.com", asset: "FaviconYouTube"),
        Shortcut(title: "Wikipedia", urlString: "https://www.wikipedia.org", asset: "FaviconWikipedia"),
        Shortcut(title: "GitHub", urlString: "https://github.com", asset: "FaviconGitHub"),
        Shortcut(title: "Reddit", urlString: "https://www.reddit.com", asset: "FaviconReddit"),
        Shortcut(title: "Maps", urlString: "https://maps.google.com", asset: "FaviconMaps"),
        Shortcut(title: "News", urlString: "https://news.google.com", asset: "FaviconNews")
    ]

    private var directory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("Shortcuts", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private var listURL: URL {
        directory.appendingPathComponent("list.json")
    }

    private func iconURL(_ id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).png")
    }

    private func save(_ image: UIImage, id: UUID) -> Bool {
        guard let data = image.pngData() else { return false }
        return (try? data.write(to: iconURL(id), options: .atomic)) != nil
    }

    private func load() {
        if let data = try? Data(contentsOf: listURL),
           let saved = try? JSONDecoder().decode([Shortcut].self, from: data) {
            items = saved
        } else {
            items = Self.defaults
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: listURL, options: .atomic)
    }
}
