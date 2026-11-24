import Observation
import SwiftUI
import WebKit

struct SiteExtension: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case style
        case script
    }

    var id: String
    var name: String
    var summary: String
    var host: String
    var kind: Kind
    var code: String
    var isEnabled: Bool
    var isBuiltIn: Bool
}

@MainActor
@Observable
final class ExtensionStore {
    private(set) var items: [SiteExtension] = []
    @ObservationIgnored var onChange: (@MainActor () -> Void)?

    init() {
        load()
    }

    func setEnabled(_ id: String, _ value: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isEnabled = value
        persist()
    }

    func add(name: String, host: String, kind: SiteExtension.Kind, code: String) {
        items.append(SiteExtension(
            id: UUID().uuidString,
            name: name,
            summary: host.isEmpty ? String(localized: "All sites") : host,
            host: host.isEmpty ? "*" : host,
            kind: kind,
            code: code,
            isEnabled: true,
            isBuiltIn: false
        ))
        persist()
    }

    func update(_ item: SiteExtension) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        persist()
    }

    func remove(_ item: SiteExtension) {
        guard !item.isBuiltIn else { return }
        items.removeAll { $0.id == item.id }
        persist()
    }

    func makeScripts() -> [WKUserScript] {
        items.filter(\.isEnabled).map { item in
            WKUserScript(source: Self.wrap(item), injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }

    private static func literal(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode([value]),
              let text = String(data: data, encoding: .utf8) else { return "\"\"" }
        return String(text.dropFirst().dropLast())
    }

    private static func wrap(_ item: SiteExtension) -> String {
        let host = literal(item.host)
        let body: String
        switch item.kind {
        case .style:
            body = "var s=document.createElement('style');s.setAttribute('data-skrrt','1');s.textContent=\(literal(item.code));(document.head||document.documentElement).appendChild(s);"
        case .script:
            body = item.code
        }
        return "(function(){try{var h=\(host);if(h!=='*'&&!location.hostname.endsWith(h))return;\(body)}catch(e){}})();"
    }

    private static let builtIns: [SiteExtension] = [
        SiteExtension(
            id: "builtin.dark",
            name: String(localized: "Force Dark Mode"),
            summary: String(localized: "Inverts light pages that have no dark theme"),
            host: "*",
            kind: .style,
            code: "html{filter:invert(1) hue-rotate(180deg)!important;background:#fff!important}img,video,picture,canvas,svg,iframe{filter:invert(1) hue-rotate(180deg)!important}",
            isEnabled: false,
            isBuiltIn: true
        ),
        SiteExtension(
            id: "builtin.cookies",
            name: String(localized: "Hide Cookie Banners"),
            summary: String(localized: "Hides common consent pop-ups"),
            host: "*",
            kind: .style,
            code: "#onetrust-banner-sdk,#onetrust-consent-sdk,#CybotCookiebotDialog,.cc-window,.cookie-banner,.cookie-notice,.cookie-consent,#cookie-banner,#cookieBanner,[id^='sp_message_container'],[class*='cookie-banner'],[class*='CookieBanner'],[aria-label*='cookie' i]{display:none!important}",
            isEnabled: true,
            isBuiltIn: true
        ),
        SiteExtension(
            id: "builtin.branding",
            name: String(localized: "Clean Search Pages"),
            summary: String(localized: "Hides the search engine logo on result pages"),
            host: "*",
            kind: .script,
            code: #"if(!/(^|\.)(google|bing|duckduckgo|yandex|startpage|ecosia)\./.test(location.hostname)&&location.hostname!=='search.brave.com')return;var s=document.createElement('style');s.textContent='#logo,#logocont,#hplogo,a[aria-label="Google"],a[title="Google"],header a[href*="duckduckgo.com"] img{display:none!important}';document.documentElement.appendChild(s);"#,
            isEnabled: true,
            isBuiltIn: true
        )
    ]

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("extensions.json")
    }

    private func load() {
        var saved: [SiteExtension] = []
        if let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode([SiteExtension].self, from: data) {
            saved = decoded
        }
        var merged = Self.builtIns.map { builtIn -> SiteExtension in
            var copy = builtIn
            if let match = saved.first(where: { $0.id == builtIn.id }) {
                copy.isEnabled = match.isEnabled
            }
            return copy
        }
        merged += saved.filter { !$0.isBuiltIn }
        items = merged
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL, options: .atomic)
        }
        onChange?()
    }
}
