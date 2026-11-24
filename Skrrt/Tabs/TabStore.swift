import Foundation
import Observation

@MainActor
@Observable
final class TabStore {
    private(set) var tabs: [Tab] = []
    private(set) var selectedID: Tab.ID?

    @ObservationIgnored var recorder: (@MainActor (String, URL) -> Void)?
    @ObservationIgnored private let settings: Settings
    @ObservationIgnored private let blocker = ContentBlocker()
    @ObservationIgnored private let sessionKey = "session.tabs"

    init(settings: Settings) {
        self.settings = settings

    }

    func start() {
        guard tabs.isEmpty else { return }
        restore()
    }

    var current: Tab? {
        tabs.first { $0.id == selectedID }
    }

    func prepare() async {
        await blocker.prepare()
        applyBlocking()
    }

    @discardableResult
    func open(_ url: URL? = nil, isPrivate: Bool = false, select: Bool = true) -> Tab {
        let tab = Tab(url: url, isPrivate: isPrivate)
        attach(tab)
        tabs.append(tab)
        if select {
            self.select(tab)
        } else {
            tab.wake()
            persist()
        }
        return tab
    }

    func select(_ tab: Tab) {
        if let previous = current, previous.id != tab.id {
            Task { await previous.captureSnapshot() }
        }
        selectedID = tab.id
        tab.wake()
        persist()
    }

    func close(_ tab: Tab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: index)
        if selectedID == tab.id {
            if tabs.isEmpty {
                open()
                return
            }
            select(tabs[min(index, tabs.count - 1)])
        } else {
            persist()
        }
    }

    func applyBlocking() {
        for tab in tabs {
            blocker.apply(to: tab, enabled: settings.blocksContent)
        }
    }

    func applyUserAgent() {
        for tab in tabs {
            tab.applyUserAgent(settings.userAgent)
        }
        current?.reload()
    }

    func submit(_ input: String, in tab: Tab) {
        guard let url = SearchEngine.resolve(input) else { return }
        tab.load(url)
    }

    private func attach(_ tab: Tab) {
        tab.applyUserAgent(settings.userAgent)
        blocker.apply(to: tab, enabled: settings.blocksContent)
        tab.onVisit = { [weak self] title, url in self?.recorder?(title, url) }
        tab.onOpenTab = { [weak self] url in self?.open(url) }
        tab.onChange = { [weak self] in self?.persist() }
    }

    private func persist() {
        let saved = tabs.filter { !$0.isPrivate }
        let session = Session(
            tabs: saved.map { SavedTab(url: $0.url?.absoluteString, title: $0.title) },
            selected: saved.firstIndex { $0.id == selectedID } ?? 0
        )
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func restore() {
        guard
            let data = UserDefaults.standard.data(forKey: sessionKey),
            let session = try? JSONDecoder().decode(Session.self, from: data),
            !session.tabs.isEmpty
        else {
            open()
            return
        }
        for saved in session.tabs {
            let tab = Tab(url: saved.url.flatMap(URL.init(string:)), title: saved.title)
            attach(tab)
            tabs.append(tab)
        }
        select(tabs[min(session.selected, tabs.count - 1)])
    }

    private struct SavedTab: Codable {
        let url: String?
        let title: String
    }

    private struct Session: Codable {
        let tabs: [SavedTab]
        let selected: Int
    }
}
