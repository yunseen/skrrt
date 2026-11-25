import Observation
import SwiftUI
import UIKit
import WebKit

@MainActor
@Observable
final class Tab: Identifiable {
    let id = UUID()
    let isPrivate: Bool
    let webView: WKWebView
    private(set) var title: String
    private(set) var url: URL?
    private(set) var progress = 0.0
    private(set) var isLoading = false
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    private(set) var isSecure = true
    private(set) var snapshot: UIImage?
    var isCompact = false
    private(set) var topColor: UIColor = .systemBackground
    @ObservationIgnored var collapsesBars = true

    @ObservationIgnored var onVisit: (@MainActor (String, URL) -> Void)?
    @ObservationIgnored var onOpenTab: (@MainActor (URL) -> Void)?
    @ObservationIgnored var onChange: (@MainActor () -> Void)?
    @ObservationIgnored private let delegate = WebDelegate()
    @ObservationIgnored private let refreshControl = UIRefreshControl()
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    @ObservationIgnored private var pendingURL: URL?
    @ObservationIgnored private var recordedURL: URL?
    @ObservationIgnored private var lastOffset: CGFloat = 0

    init(url: URL?, title: String = "", isPrivate: Bool = false) {
        self.isPrivate = isPrivate
        self.title = title
        self.url = url
        self.pendingURL = url
        self.webView = WKWebView(frame: .zero, configuration: WebEngine.configuration(isPrivate: isPrivate))
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        webView.scrollView.refreshControl = refreshControl
        delegate.onFinish = { [weak self] in self?.finished() }
        delegate.onOpen = { [weak self] url in self?.onOpenTab?(url) }
        refreshControl.addAction(UIAction { [weak self] _ in self?.reload() }, for: .valueChanged)
        observe()
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        return url?.displayHost ?? ""
    }

    func wake() {
        guard let target = pendingURL else { return }
        pendingURL = nil
        webView.load(URLRequest(url: target))
    }

    func load(_ target: URL) {
        pendingURL = nil
        url = target
        isCompact = false
        webView.load(URLRequest(url: target))
        onChange?()
    }

    func reload() {
        if webView.url != nil {
            webView.reload()
        } else if let url {
            webView.load(URLRequest(url: url))
        } else {
            refreshControl.endRefreshing()
        }
    }

    func stop() {
        webView.stopLoading()
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func startElementPicker(language: String) {
        webView.evaluateJavaScript(SiteRules.pickerSource(language: language), in: nil, in: PluginRuntime.world) { _ in }
    }

    func expand() {
        setCompact(false)
    }

    func applyPreferences(_ settings: Settings, scripts: [WKUserScript]) {
        webView.customUserAgent = nil
        webView.isInspectable = settings.webInspector
        collapsesBars = settings.collapsesBars
        if !collapsesBars { setCompact(false) }
        webView.overrideUserInterfaceStyle = settings.webStyle
        delegate.allowsJavaScript = settings.allowsJavaScript
        delegate.blocksPopups = settings.blocksPopups
        let upgrade = settings.upgradesHTTPS
        let strip = settings.stripsTracking
        delegate.rewrite = { url in URLCleaner.rewrite(url, upgradeHTTPS: upgrade, stripTracking: strip) }
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        if settings.smartDark && settings.darkPages != .off {
            controller.addUserScript(SmartDark.script)
        }
        for script in scripts {
            controller.addUserScript(script)
        }
    }

    func captureSnapshot() async {
        guard url != nil, webView.window != nil else { return }
        let configuration = WKSnapshotConfiguration()
        configuration.snapshotWidth = 420
        let image: UIImage? = await withCheckedContinuation { continuation in
            var finished = false
            let finish: (UIImage?) -> Void = { result in
                guard !finished else { return }
                finished = true
                continuation.resume(returning: result)
            }
            webView.takeSnapshot(with: configuration) { result, _ in
                finish(result)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                finish(nil)
            }
        }
        if let image {
            snapshot = image
        }
    }

    private func observe() {
        observations = [
            webView.observe(\.title) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.url) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.estimatedProgress) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.isLoading) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.canGoBack) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.canGoForward) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.hasOnlySecureContent) { [weak self] _, _ in Task { @MainActor in self?.syncState() } },
            webView.observe(\.themeColor) { [weak self] _, _ in Task { @MainActor in self?.refreshTopColor() } },
            webView.scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let offset = change.newValue?.y else { return }
                MainActor.assumeIsolated { self?.scrolled(to: offset) }
            }
        ]
    }

    private func syncState() {
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            title = pageTitle
        }
        if let current = webView.url, current != url {
            url = current
            onChange?()
        }
        let newProgress = webView.estimatedProgress
        if abs(newProgress - progress) >= 0.02 || newProgress >= 1 || newProgress == 0 {
            progress = newProgress
        }
        if isLoading != webView.isLoading {
            isLoading = webView.isLoading
        }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if url?.scheme?.lowercased() == "http" {
            isSecure = false
        } else {
            isSecure = url == nil || webView.hasOnlySecureContent
        }
        if !isLoading {
            refreshControl.endRefreshing()
        }
    }

    private func finished() {
        syncState()
        if !isPrivate,
           let current = webView.url,
           current != recordedURL,
           let scheme = current.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            recordedURL = current
            onVisit?(displayTitle, current)
        }
        refreshTopColor()
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            refreshTopColor()
            try? await Task.sleep(for: .milliseconds(1300))
            refreshTopColor()
            await captureSnapshot()
        }
    }

    private static let colorProbe = """
    (function(){var b=document.body,h=document.documentElement;
    function c(e){return e?getComputedStyle(e).backgroundColor:'';}
    var v=c(b);
    if(!v||v==='transparent'||/rgba\\([^)]*,\\s*0\\)/.test(v))v=c(h);
    return v+'|'+(h.hasAttribute('data-skrrt-dark')?'1':'0');})()
    """

    /// Colors the area behind the status bar like the page, the way Safari does.
    func refreshTopColor() {
        guard url != nil else {
            topColor = .systemBackground
            return
        }
        webView.evaluateJavaScript(Self.colorProbe) { [weak self] result, _ in
            guard let text = result as? String else { return }
            MainActor.assumeIsolated { self?.applyProbe(text) }
        }
    }

    private func applyProbe(_ text: String) {
        let parts = text.split(separator: "|", omittingEmptySubsequences: false)
        let inverted = parts.count > 1 && parts[1] == "1"
        if !inverted, let theme = webView.themeColor {
            setTopColor(theme)
            return
        }
        let numbers = (parts.first.map(String.init) ?? "")
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .filter { !$0.isEmpty }
            .compactMap(Double.init)
        guard numbers.count >= 3, (numbers.count < 4 || numbers[3] >= 0.1) else {
            setTopColor(.systemBackground)
            return
        }
        var red = numbers[0], green = numbers[1], blue = numbers[2]
        if inverted {
            red = 255 - red
            green = 255 - green
            blue = 255 - blue
        }
        setTopColor(UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1))
    }

    private func setTopColor(_ color: UIColor) {
        guard color != topColor else { return }
        topColor = color
        webView.underPageBackgroundColor = color
    }

    private func scrolled(to offset: CGFloat) {
        let delta = offset - lastOffset
        lastOffset = offset
        guard collapsesBars, abs(delta) > 6 else { return }
        if offset <= 0 {
            setCompact(false)
        } else if delta > 0 && offset > 80 {
            setCompact(true)
        } else if delta < 0 {
            setCompact(false)
        }
    }

    private func setCompact(_ value: Bool) {
        guard isCompact != value else { return }
        withAnimation(.smooth(duration: 0.35)) {
            isCompact = value
        }
    }
}
