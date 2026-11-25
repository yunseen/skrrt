import SwiftUI

enum PluginDocs {
    static let url = URL(string: "https://telegra.ph/Skrrt-plaginy-i-API-CSS-JavaScript-11-25")!
}

/// Text in several languages, as written in a plugin manifest: `{ "en": "...", "ru": "..." }`.
struct L10n: Codable, Equatable {
    var values: [String: String]

    init(_ values: [String: String]) {
        self.values = values
    }

    init(_ text: String) {
        values = ["en": text]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = (try? container.decode([String: String].self)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    func text(_ language: String) -> String {
        values[language] ?? values["en"] ?? values.values.first ?? ""
    }
}

enum PluginCategory: String, Codable, CaseIterable, Identifiable {
    case privacy
    case video
    case reading
    case look
    case tools
    case mine

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .privacy: "Privacy"
        case .video: "Video"
        case .reading: "Reading"
        case .look: "Look"
        case .tools: "Tools"
        case .mine: "My Plugins"
        }
    }

    var symbol: String {
        switch self {
        case .privacy: "hand.raised.fill"
        case .video: "play.rectangle.fill"
        case .reading: "book.fill"
        case .look: "paintpalette.fill"
        case .tools: "wrench.and.screwdriver.fill"
        case .mine: "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .privacy: Color(red: 0.2, green: 0.78, blue: 0.45)
        case .video: Color(red: 1, green: 0.27, blue: 0.23)
        case .reading: Color(red: 1, green: 0.58, blue: 0.15)
        case .look: Color(red: 0.62, green: 0.45, blue: 1)
        case .tools: Color(red: 0.039, green: 0.518, blue: 1)
        case .mine: Color(red: 0.2, green: 0.8, blue: 0.95)
        }
    }
}

struct PluginIcon: Codable, Equatable {
    var symbol: String
    var color: String
    var logoHost: String?

    static let `default` = PluginIcon(symbol: "puzzlepiece.extension.fill", color: "#0A84FF", logoHost: nil)

    var tint: Color {
        Color(hex: color) ?? Color.accentColor
    }
}

enum OptionValue: Codable, Equatable {
    case bool(Bool)
    case number(Double)
    case text(String)
    case list([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([String].self) {
            self = .list(value)
        } else {
            self = .text((try? container.decode(String.self)) ?? "")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .text(let value): try container.encode(value)
        case .list(let value): try container.encode(value)
        }
    }

    var jsonObject: Any {
        switch self {
        case .bool(let value): value
        case .number(let value): value
        case .text(let value): value
        case .list(let value): value
        }
    }

    var boolValue: Bool {
        if case .bool(let value) = self { return value }
        return false
    }

    var numberValue: Double {
        if case .number(let value) = self { return value }
        return 0
    }

    var textValue: String {
        if case .text(let value) = self { return value }
        return ""
    }

    var listValue: [String] {
        if case .list(let value) = self { return value }
        return []
    }
}

enum OptionType: String, Codable {
    case toggle
    case slider
    case choice
    case multichoice
    case text
}

struct PluginChoice: Codable, Equatable, Identifiable {
    var value: String
    var title: L10n

    var id: String { value }
}

struct PluginOption: Codable, Equatable, Identifiable {
    var key: String
    var type: OptionType
    var title: L10n
    var hint: L10n?
    var defaultValue: OptionValue
    var min: Double?
    var max: Double?
    var step: Double?
    var unit: String?
    var choices: [PluginChoice]?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, type, title, hint, min, max, step, unit, choices
        case defaultValue = "default"
    }
}

/// What a plugin may reach, shown to the user before and after installing, like the permissions of a Chrome extension.
struct PluginPermissions: Codable, Equatable {
    var hosts: [String] = []
    var tools: [String] = []

    init(hosts: [String] = [], tools: [String] = []) {
        self.hosts = hosts
        self.tools = tools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hosts = (try? container.decode([String].self, forKey: .hosts)) ?? []
        tools = (try? container.decode([String].self, forKey: .tools)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case hosts, tools
    }

    func allows(host: String) -> Bool {
        let clean = host.lowercased()
        return hosts.contains { allowed in
            let base = allowed.lowercased().replacingOccurrences(of: "*.", with: "")
            return clean == base || clean.hasSuffix("." + base)
        }
    }
}

struct Plugin: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case script
        case style
    }

    var id: String
    var name: L10n
    var summary: L10n
    var details: L10n
    var icon: PluginIcon
    var category: PluginCategory
    var kind: Kind
    var matches: [String]
    var excludes: [String]
    var runsAtStart: Bool
    var inPage: Bool
    var version: String
    var author: String
    var code: String
    var permissions: PluginPermissions
    var options: [PluginOption]
    var values: [String: OptionValue]
    var blockedHosts: [String]
    var isEnabled: Bool
    /// The id in the plugin store, or nil for plugins you wrote or imported yourself.
    var storeID: String?

    var isUser: Bool { storeID == nil }

    func displayName(_ language: String) -> String {
        name.text(language)
    }

    func displaySummary(_ language: String) -> String {
        summary.text(language)
    }

    /// Saved values on top of the defaults from the manifest.
    var effectiveValues: [String: OptionValue] {
        var result: [String: OptionValue] = [:]
        for option in options {
            result[option.key] = values[option.key] ?? option.defaultValue
        }
        return result
    }

    func value(for option: PluginOption) -> OptionValue {
        values[option.key] ?? option.defaultValue
    }

    /// True when the plugin would run on this address, ignoring the on and off switches.
    func applies(to host: String) -> Bool {
        let clean = host.lowercased().replacingOccurrences(of: "www.", with: "")
        if excludes.contains(where: { Self.hostMatches($0, clean) }) { return false }
        return matches.isEmpty || matches.contains { Self.hostMatches($0, clean) }
    }

    func isActive(on host: String) -> Bool {
        isEnabled && applies(to: host) && !blockedHosts.contains(where: { Self.hostMatches($0, host.lowercased()) })
    }

    static func hostMatches(_ pattern: String, _ host: String) -> Bool {
        var base = pattern.lowercased()
        if base == "*" || base == "<all_urls>" { return true }
        if let range = base.range(of: "://") { base = String(base[range.upperBound...]) }
        if let slash = base.firstIndex(of: "/") { base = String(base[..<slash]) }
        base = base.replacingOccurrences(of: "www.", with: "").replacingOccurrences(of: "*.", with: "")
        return !base.isEmpty && (host == base || host.hasSuffix("." + base))
    }

    /// The plugin as a shareable file, including its metadata header.
    var exportSource: String {
        let language = "en"
        var lines: [String] = []
        let open = kind == .style ? "/* ==Plugin==" : "// ==Plugin=="
        let close = kind == .style ? "   ==/Plugin== */" : "// ==/Plugin=="
        let prefix = kind == .style ? "   " : "// "
        lines.append(open)
        lines.append("\(prefix)@name        \(name.text(language))")
        if !summary.text(language).isEmpty { lines.append("\(prefix)@description \(summary.text(language))") }
        lines.append("\(prefix)@version     \(version)")
        lines.append("\(prefix)@icon        \(icon.symbol)")
        for pattern in matches { lines.append("\(prefix)@match       \(pattern)") }
        for pattern in excludes { lines.append("\(prefix)@exclude     \(pattern)") }
        if runsAtStart { lines.append("\(prefix)@run-at      document-start") }
        lines.append(close)
        lines.append("")
        lines.append(code)
        return lines.joined(separator: "\n")
    }
}

/// The JSON file that describes a plugin in the store.
struct PluginManifest: Decodable {
    var id: String
    var name: L10n
    var summary: L10n
    var description: L10n?
    var icon: PluginIcon?
    var category: PluginCategory?
    var kind: Plugin.Kind
    var file: String
    var version: String
    var author: String?
    var matches: [String]?
    var excludes: [String]?
    var runAt: String?
    var permissions: PluginPermissions?
    var options: [PluginOption]?

    func makePlugin(code: String) -> Plugin {
        Plugin(
            id: id,
            name: name,
            summary: summary,
            details: description ?? summary,
            icon: icon ?? .default,
            category: category ?? .tools,
            kind: kind,
            matches: matches ?? [],
            excludes: excludes ?? [],
            runsAtStart: runAt == "start",
            inPage: false,
            version: version,
            author: author ?? "Skrrt",
            code: code,
            permissions: permissions ?? PluginPermissions(),
            options: options ?? [],
            values: [:],
            blockedHosts: [],
            isEnabled: true,
            storeID: id
        )
    }
}

/// Reads the optional `==Plugin==` (or `==UserScript==`) header of a JS or CSS file.
struct PluginMeta {
    var name: String?
    var summary: String?
    var version: String?
    var icon: String?
    var matches: [String] = []
    var excludes: [String] = []
    var runsAtStart = false

    static func parse(_ source: String) -> PluginMeta {
        var meta = PluginMeta()
        guard let open = source.range(of: "==Plugin==") ?? source.range(of: "==UserScript==") else { return meta }
        let tail = source[open.upperBound...]
        let end = tail.range(of: "==/Plugin==") ?? tail.range(of: "==/UserScript==")
        let block = end.map { String(tail[..<$0.lowerBound]) } ?? String(tail.prefix(2000))

        for rawLine in block.split(whereSeparator: \.isNewline) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            while let first = line.first, first == "/" || first == "*" || first == "#" || first == " " {
                line.removeFirst()
            }
            guard line.hasPrefix("@") else { continue }
            let parts = line.dropFirst().split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" })
            guard let key = parts.first?.lowercased() else { continue }
            let value = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            switch key {
            case "name": meta.name = value
            case "description": meta.summary = value
            case "version": meta.version = value
            case "icon": meta.icon = value
            case "match", "include", "host":
                meta.matches += value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            case "exclude":
                meta.excludes += value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            case "run-at": meta.runsAtStart = value.lowercased().contains("start")
            default: break
            }
        }
        return meta
    }
}
