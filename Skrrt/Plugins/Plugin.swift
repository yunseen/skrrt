import SwiftUI

enum PluginCategory: String, Codable, CaseIterable, Identifiable {
    case appearance
    case privacy
    case video
    case reading
    case tools
    case mine

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .appearance: "Look"
        case .privacy: "Privacy"
        case .video: "Video"
        case .reading: "Reading"
        case .tools: "Tools"
        case .mine: "My Plugins"
        }
    }

    var color: Color {
        switch self {
        case .appearance: Color(red: 0.62, green: 0.45, blue: 1)
        case .privacy: Color(red: 0.2, green: 0.78, blue: 0.45)
        case .video: Color(red: 1, green: 0.27, blue: 0.23)
        case .reading: Color(red: 1, green: 0.58, blue: 0.15)
        case .tools: Color(red: 0.039, green: 0.518, blue: 1)
        case .mine: Color(red: 0.2, green: 0.8, blue: 0.95)
        }
    }
}

struct Plugin: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case script
        case style
    }

    var id: String
    var name: String
    var summary: String
    var icon: String
    var category: PluginCategory
    var kind: Kind
    var matches: [String]
    var excludes: [String]
    var runsAtStart: Bool
    var version: String
    var code: String
    var isEnabled: Bool
    var isBuiltIn: Bool

    /// The plugin as a shareable file, including its metadata header.
    var exportSource: String {
        var lines: [String] = []
        let open = kind == .style ? "/* ==Plugin==" : "// ==Plugin=="
        let close = kind == .style ? "   ==/Plugin== */" : "// ==/Plugin=="
        let prefix = kind == .style ? "   " : "// "
        lines.append(open)
        lines.append("\(prefix)@name        \(name)")
        if !summary.isEmpty { lines.append("\(prefix)@description \(summary)") }
        lines.append("\(prefix)@version     \(version)")
        lines.append("\(prefix)@icon        \(icon)")
        for pattern in matches { lines.append("\(prefix)@match       \(pattern)") }
        for pattern in excludes { lines.append("\(prefix)@exclude     \(pattern)") }
        if runsAtStart { lines.append("\(prefix)@run-at      document-start") }
        lines.append(close)
        lines.append("")
        lines.append(code)
        return lines.joined(separator: "\n")
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
