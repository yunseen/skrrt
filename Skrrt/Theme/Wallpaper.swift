import SwiftUI
import UIKit

enum WallpaperStorage {
    private static var url: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("wallpaper.jpg")
    }

    static func save(_ data: Data) -> Bool {
        guard let source = UIImage(data: data) else { return false }
        let longest = max(source.size.width, source.size.height)
        let factor = min(1, 1800 / longest)
        let size = CGSize(width: source.size.width * factor, height: source.size.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let scaled = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = scaled.jpegData(compressionQuality: 0.85) else { return false }
        return (try? jpeg.write(to: url, options: .atomic)) != nil
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

private struct WallpaperPausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True while another screen covers the wallpaper, so it can stop animating and save battery.
    var wallpaperPaused: Bool {
        get { self[WallpaperPausedKey.self] }
        set { self[WallpaperPausedKey.self] = newValue }
    }
}

struct WallpaperView: View {
    @Environment(Settings.self) private var settings
    @Environment(\.wallpaperPaused) private var paused
    @Environment(\.scenePhase) private var scenePhase

    private var animated: Bool {
        settings.animatesWallpaper && !paused && scenePhase == .active
    }

    var body: some View {
        content
            .drawingGroup()
            .blur(radius: settings.wallpaperBlur, opaque: true)
            .scaleEffect(settings.wallpaperBlur > 0 ? 1.12 : 1)
            .clipped()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        switch settings.wallpaper {
        case .curtain:
            CurtainWallpaper(animated: animated)
        case .ice:
            IceWallpaper(animated: animated)
        case .aurora:
            AuroraBackground()
        case .photo:
            PhotoWallpaper(animated: animated, revision: settings.photoRevision)
        }
    }
}


struct CurtainWallpaper: View {
    let animated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            Canvas { gc, size in
                let panels = 5
                let width = size.width / CGFloat(panels)
                for index in 0..<panels {
                    let phase = t * 2 * .pi / 14 + Double(index) * 1.25
                    let glow = 0.50 + 0.07 * sin(phase)
                    let lift = index % 2 == 0 ? 1.0 : 0.93
                    let rect = CGRect(x: CGFloat(index) * width - 1, y: 0, width: width + 2, height: size.height)
                    let stops: [Gradient.Stop] = [
                        .init(color: Color(red: 0.01, green: 0.01, blue: 0.03), location: 0),
                        .init(color: Color(red: 0.02, green: 0.02, blue: 0.08), location: max(0.05, glow - 0.20)),
                        .init(color: Color(red: 0.10 * lift, green: 0.12 * lift, blue: 0.55 * lift), location: glow),
                        .init(color: Color(red: 0.25 * lift, green: 0.45 * lift, blue: 0.95 * lift), location: min(0.95, glow + 0.12)),
                        .init(color: Color(red: 0.55 * lift, green: 0.78 * lift, blue: 1.0 * lift), location: min(0.97, glow + 0.27)),
                        .init(color: Color(red: 0.30 * lift, green: 0.62 * lift, blue: 1.0 * lift), location: 1)
                    ]
                    gc.fill(
                        Path(rect),
                        with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: rect.midX, y: 0), endPoint: CGPoint(x: rect.midX, y: size.height))
                    )
                    let arch = CGRect(x: rect.midX - width * 0.9, y: size.height * glow - width * 0.5, width: width * 1.8, height: width * 1.2)
                    gc.fill(
                        Path(ellipseIn: arch),
                        with: .radialGradient(
                            Gradient(colors: [Color(red: 0.3, green: 0.5, blue: 1).opacity(0.38), .clear]),
                            center: CGPoint(x: arch.midX, y: arch.midY),
                            startRadius: 0,
                            endRadius: width * 0.9
                        )
                    )
                    if index > 0 {
                        var seam = Path()
                        seam.move(to: CGPoint(x: CGFloat(index) * width, y: size.height * 0.3))
                        seam.addLine(to: CGPoint(x: CGFloat(index) * width, y: size.height))
                        gc.stroke(seam, with: .color(.white.opacity(0.10)), lineWidth: 1)
                    }
                }
            }
        }
    }
}

struct IceWallpaper: View {
    let animated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            Canvas { gc, size in
                gc.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.93, green: 0.95, blue: 0.98)))
                let breath = sin(t * 2 * .pi / 10)
                let gap = 0.075 + 0.025 * breath
                let radiusX = size.width * (0.40 + 0.04 * breath)
                let radiusY = size.height * 0.17
                for direction in [-1.0, 1.0] {
                    let center = CGPoint(x: size.width / 2, y: size.height * (0.5 + direction * (gap + 0.13)))
                    let rect = CGRect(x: center.x - radiusX, y: center.y - radiusY, width: radiusX * 2, height: radiusY * 2)
                    gc.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: Color(red: 0.01, green: 0.03, blue: 0.30), location: 0),
                                .init(color: Color(red: 0.16, green: 0.28, blue: 0.70).opacity(0.85), location: 0.45),
                                .init(color: Color(red: 0.55, green: 0.66, blue: 0.90).opacity(0.35), location: 0.8),
                                .init(color: .clear, location: 1)
                            ]),
                            center: CGPoint(x: center.x, y: center.y - direction * radiusY * 0.45),
                            startRadius: 0,
                            endRadius: radiusX
                        )
                    )
                }
                let stripes = 26
                let width = size.width / CGFloat(stripes)
                for index in 0..<stripes where index % 2 == 0 {
                    let rect = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: size.height)
                    gc.fill(Path(rect), with: .color(.white.opacity(0.16)))
                }
            }
        }
    }
}

struct PhotoWallpaper: View {
    let animated: Bool
    let revision: Int

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
                    let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
                    GeometryReader { proxy in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .scaleEffect(1.10 + 0.05 * sin(t * 2 * .pi / 24))
                            .offset(x: 14 * sin(t * 2 * .pi / 31), y: 10 * cos(t * 2 * .pi / 27))
                            .clipped()
                    }
                }
            } else {
                CurtainWallpaper(animated: animated)
            }
        }
        .task(id: revision) {
            image = WallpaperStorage.load()
        }
    }
}
