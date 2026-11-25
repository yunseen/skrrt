import Lottie
import SwiftUI
import UIKit

/// Telegram animated emoji (.tgs files). A .tgs is a gzip-compressed Lottie animation.
enum EmojiLibrary {
    private static var cache: [Int: LottieAnimation] = [:]

    static let count = 150
    static let devLogoCount = 200

    static func animation(_ index: Int) -> LottieAnimation? {
        if let cached = cache[index] { return cached }
        let name = String(format: "emoji_%03d", index)
        guard let url = Bundle.main.url(forResource: name, withExtension: "tgs"),
              let compressed = try? Data(contentsOf: url),
              let json = gunzip(compressed),
              let animation = try? LottieAnimation.from(data: json) else { return nil }
        cache[index] = animation
        return animation
    }

    static func devLogo(_ index: Int) -> UIImage? {
        let name = String(format: "devlogo_%03d", index)
        guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Unpacks a gzip file: skips the header, then inflates the raw deflate stream.
    static func gunzip(_ data: Data) -> Data? {
        guard data.count > 18, data[data.startIndex] == 0x1f, data[data.startIndex + 1] == 0x8b else { return nil }
        let bytes = [UInt8](data)
        let flags = bytes[3]
        var offset = 10
        if flags & 0x04 != 0 {
            guard bytes.count > offset + 2 else { return nil }
            offset += 2 + (Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8))
        }
        if flags & 0x08 != 0 {
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x10 != 0 {
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 { offset += 2 }
        guard offset < bytes.count - 8 else { return nil }
        let body = Data(bytes[offset..<(bytes.count - 8)])
        return try? (body as NSData).decompressed(using: .zlib) as Data
    }
}

/// Numbers of the animated emoji used in the app, chosen to match what they stand for.
enum Emoji {
    static let sleepy = 73          // 😴 nothing here yet
    static let yawning = 72         // 🥱 empty history
    static let star = 125           // ⭐️ bookmarks
    static let thinking = 54        // 🤔 no plugins
    static let seeNoEvil = 97       // 🙈 nothing hidden
    static let food = 132           // 🍴 cookies
    static let monocle = 25         // 🧐 search
    static let party = 30           // 🥳 installed
    static let sad = 41             // 😢 something failed
    static let begging = 40         // 🥺 no results
    static let heart = 141          // ❤️ about
    static let shush = 57           // 🤫 private tab
    static let sigh = 76            // 😮‍💨 offline
    static let sparkles = 127       // ✨ update available
    static let thumbsUp = 104       // 👍 done
}

/// A Telegram animated emoji. When the file is missing it falls back to nothing, so layouts never break.
struct AnimatedEmoji: UIViewRepresentable {
    let index: Int
    var animated = true

    func makeUIView(context: Context) -> UIView {
        let host = UIView()
        host.backgroundColor = .clear
        host.isUserInteractionEnabled = false
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.backgroundBehavior = .pauseAndRestore
        view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
            view.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        configure(view)
        return host
    }

    func updateUIView(_ host: UIView, context: Context) {
        guard let view = host.subviews.first as? LottieAnimationView else { return }
        configure(view)
    }

    private func configure(_ view: LottieAnimationView) {
        if view.animation == nil || view.tag != index {
            view.tag = index
            view.animation = EmojiLibrary.animation(index)
        }
        if animated {
            if !view.isAnimationPlaying { view.play() }
        } else {
            view.stop()
            view.currentProgress = 0.4
        }
    }
}

/// A placeholder for screens with nothing to show: an animated emoji, a title and a hint.
struct EmptyState: View {
    let emoji: Int
    let title: LocalizedStringKey
    var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 10) {
            AnimatedEmoji(index: emoji)
                .frame(width: 96, height: 96)
            Text(title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
}
