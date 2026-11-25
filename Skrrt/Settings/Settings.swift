import Observation
import SwiftUI

@MainActor
@Observable
final class Settings {
    var appearance: Appearance { didSet { store(appearance.rawValue, Key.appearance) } }
    var language: Language { didSet { store(language.rawValue, Key.language) } }

    var searchEngine: SearchEngineKind { didSet { store(searchEngine.rawValue, Key.searchEngine) } }
    var customSearchURL: String { didSet { store(customSearchURL, Key.customSearchURL) } }
    var showsSuggestions: Bool { didSet { store(showsSuggestions, Key.showsSuggestions) } }

    var accent: AccentChoice { didSet { store(accent.rawValue, Key.accent) } }
    var customAccentHex: String { didSet { store(customAccentHex, Key.customAccentHex) } }
    var darkPages: DarkPages { didSet { store(darkPages.rawValue, Key.darkPages) } }
    var smartDark: Bool { didSet { store(smartDark, Key.smartDark) } }

    var wallpaper: WallpaperStyle { didSet { store(wallpaper.rawValue, Key.wallpaper) } }
    var wallpaperBlur: Double { didSet { store(wallpaperBlur, Key.wallpaperBlur) } }
    var animatesWallpaper: Bool { didSet { store(animatesWallpaper, Key.animatesWallpaper) } }
    var tileShape: TileShape { didSet { store(tileShape.rawValue, Key.tileShape) } }
    var showsTileTitles: Bool { didSet { store(showsTileTitles, Key.showsTileTitles) } }
    var tileColumns: Int { didSet { store(tileColumns, Key.tileColumns) } }
    var photoRevision: Int { didSet { store(photoRevision, Key.photoRevision) } }

    var blocksContent: Bool { didSet { store(blocksContent, Key.blocksContent) } }
    var hidesAddresses: Bool { didSet { store(hidesAddresses, Key.hidesAddresses) } }
    var upgradesHTTPS: Bool { didSet { store(upgradesHTTPS, Key.upgradesHTTPS) } }
    var stripsTracking: Bool { didSet { store(stripsTracking, Key.stripsTracking) } }
    var blocksPopups: Bool { didSet { store(blocksPopups, Key.blocksPopups) } }
    var allowsJavaScript: Bool { didSet { store(allowsJavaScript, Key.allowsJavaScript) } }
    var clearsOnLaunch: Bool { didSet { store(clearsOnLaunch, Key.clearsOnLaunch) } }

    var restoresTabs: Bool { didSet { store(restoresTabs, Key.restoresTabs) } }
    var collapsesBars: Bool { didSet { store(collapsesBars, Key.collapsesBars) } }
    var showsShield: Bool { didSet { store(showsShield, Key.showsShield) } }
    var webInspector: Bool { didSet { store(webInspector, Key.webInspector) } }

    init() {
        let defaults = UserDefaults.standard
        appearance = Appearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        language = Language(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .russian

        searchEngine = SearchEngineKind(rawValue: defaults.string(forKey: Key.searchEngine) ?? "") ?? .duckduckgo
        customSearchURL = defaults.string(forKey: Key.customSearchURL) ?? "https://duckduckgo.com/?q=%s"
        showsSuggestions = defaults.object(forKey: Key.showsSuggestions) as? Bool ?? true

        accent = AccentChoice(rawValue: defaults.string(forKey: Key.accent) ?? "") ?? .blue
        customAccentHex = defaults.string(forKey: Key.customAccentHex) ?? "0A84FF"
        darkPages = DarkPages(rawValue: defaults.string(forKey: Key.darkPages) ?? "") ?? .auto
        smartDark = defaults.object(forKey: Key.smartDark) as? Bool ?? true

        wallpaper = WallpaperStyle(rawValue: defaults.string(forKey: Key.wallpaper) ?? "") ?? .curtain
        wallpaperBlur = defaults.object(forKey: Key.wallpaperBlur) as? Double ?? 6
        animatesWallpaper = defaults.object(forKey: Key.animatesWallpaper) as? Bool ?? true
        tileShape = TileShape(rawValue: defaults.string(forKey: Key.tileShape) ?? "") ?? .squircle
        showsTileTitles = defaults.object(forKey: Key.showsTileTitles) as? Bool ?? true
        tileColumns = defaults.object(forKey: Key.tileColumns) as? Int ?? 4
        photoRevision = defaults.integer(forKey: Key.photoRevision)

        blocksContent = defaults.object(forKey: Key.blocksContent) as? Bool ?? true
        hidesAddresses = defaults.bool(forKey: Key.hidesAddresses)
        upgradesHTTPS = defaults.object(forKey: Key.upgradesHTTPS) as? Bool ?? true
        stripsTracking = defaults.object(forKey: Key.stripsTracking) as? Bool ?? true
        blocksPopups = defaults.bool(forKey: Key.blocksPopups)
        allowsJavaScript = defaults.object(forKey: Key.allowsJavaScript) as? Bool ?? true
        clearsOnLaunch = defaults.bool(forKey: Key.clearsOnLaunch)

        restoresTabs = defaults.object(forKey: Key.restoresTabs) as? Bool ?? true
        collapsesBars = defaults.object(forKey: Key.collapsesBars) as? Bool ?? true
        showsShield = defaults.object(forKey: Key.showsShield) as? Bool ?? true
        webInspector = defaults.bool(forKey: Key.webInspector)
    }

    var accentColor: Color {
        if accent == .custom {
            return Color(hex: customAccentHex) ?? Palette.blue
        }
        return accent.preset ?? Palette.blue
    }

    var searchTemplate: String {
        if searchEngine == .custom, customSearchURL.contains("%s") {
            return customSearchURL
        }
        return searchEngine.searchTemplate
    }

    /// "ru" or "en": the language plugins and the store use for names and messages.
    var languageCode: String {
        switch language {
        case .russian: return "ru"
        case .english: return "en"
        case .system: return Locale.current.language.languageCode?.identifier == "ru" ? "ru" : "en"
        }
    }

    var webStyle: UIUserInterfaceStyle {
        switch darkPages {
        case .off:
            return .light
        case .always:
            return .dark
        case .auto:
            switch appearance {
            case .system: return .unspecified
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    private func store(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private enum Key {
        static let language = "settings.language"
        static let appearance = "settings.appearance"
        static let blocksContent = "settings.blocksContent"
        static let hidesAddresses = "settings.hidesAddresses"
        static let searchEngine = "settings.searchEngine"
        static let customSearchURL = "settings.customSearchURL"
        static let showsSuggestions = "settings.showsSuggestions"
        static let accent = "settings.accent"
        static let customAccentHex = "settings.customAccentHex"
        static let darkPages = "settings.darkPages"
        static let smartDark = "settings.smartDark"
        static let wallpaper = "settings.wallpaper"
        static let wallpaperBlur = "settings.wallpaperBlur"
        static let animatesWallpaper = "settings.animatesWallpaper"
        static let tileShape = "settings.tileShape"
        static let showsTileTitles = "settings.showsTileTitles"
        static let tileColumns = "settings.tileColumns"
        static let photoRevision = "settings.photoRevision"
        static let upgradesHTTPS = "settings.upgradesHTTPS"
        static let stripsTracking = "settings.stripsTracking"
        static let blocksPopups = "settings.blocksPopups"
        static let allowsJavaScript = "settings.allowsJavaScript"
        static let clearsOnLaunch = "settings.clearsOnLaunch"
        static let restoresTabs = "settings.restoresTabs"
        static let collapsesBars = "settings.collapsesBars"
        static let showsShield = "settings.showsShield"
        static let webInspector = "settings.webInspector"
    }
}
