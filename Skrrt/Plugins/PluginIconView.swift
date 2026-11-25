import SwiftUI
import UIKit

/// Keeps the logos of websites that plugins belong to, on disk, so they are downloaded only once.
@MainActor
final class SiteIcons {
    static let shared = SiteIcons()

    private var memory: [String: UIImage] = [:]
    private var failed: Set<String> = []

    private var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SiteIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func cached(_ host: String) -> UIImage? {
        if let image = memory[host] { return image }
        let file = directory.appendingPathComponent("\(host).png")
        guard let data = try? Data(contentsOf: file), let image = UIImage(data: data) else { return nil }
        memory[host] = image
        return image
    }

    func load(_ host: String) async -> UIImage? {
        if let image = cached(host) { return image }
        guard !failed.contains(host), let url = URL(string: "https://\(host)") else { return nil }
        guard let image = await IconFetcher.fetch(for: url) else {
            failed.insert(host)
            return nil
        }
        memory[host] = image
        if let data = image.pngData() {
            try? data.write(to: directory.appendingPathComponent("\(host).png"), options: .atomic)
        }
        return image
    }
}

/// The logo of a plugin: the logo of its website when there is one, otherwise a symbol on a colored tile.
struct PluginIconView: View {
    let icon: PluginIcon
    var size: CGFloat = 46

    @State private var logo: UIImage?

    var body: some View {
        Group {
            if let emoji = icon.emoji {
                AnimatedEmoji(index: emoji, animated: false)
                    .padding(size * 0.1)
                    .frame(width: size, height: size)
                    .background(Color.primary.opacity(0.06))
            } else if let devLogo = icon.devLogo, let image = EmojiLibrary.devLogo(devLogo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.1)
                    .frame(width: size, height: size)
                    .background(Color.primary.opacity(0.06))
            } else if let logo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .background(Color.white)
            } else {
                Image(systemName: icon.symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(icon.tint.gradient)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .task(id: icon.logoHost) {
            guard icon.emoji == nil, icon.devLogo == nil, let host = icon.logoHost else { return }
            if let cached = SiteIcons.shared.cached(host) {
                logo = cached
            } else {
                logo = await SiteIcons.shared.load(host)
            }
        }
    }
}
