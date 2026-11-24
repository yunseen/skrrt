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

    func expand() {
        setCompact(false)
    }

    func applyUserAgent(_ mode: UserAgentMode) {
        webView.customUserAgent = mode.userAgent
        delegate.prefersDesktop = mode == .desktop
    }

    func applyPreferences(_ settings: Settings, scripts: [WKUserScript]) {
        applyUserAgent(settings.userAgent)
        webView.overrideUserInterfaceStyle = settings.webStyle
        delegate.allowsJavaScript = settings.allowsJavaScript
        delegate.blocksPopups = settings.blocksPopups
        let upgrade = settings.upgradesHTTPS
        let strip = settings.stripsTracking
        delegate.rewrite = { url in URLCleaner.rewrite(url, upgradeHTTPS: upgrade, stripTracking: strip) }
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
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
            webView.scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let offset = change.newValue?.y else { return }
                Task { @MainActor in self?.scrolled(to: offset) }
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
        progress = webView.estimatedProgress
        isLoading = webView.isLoading
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
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await captureSnapshot()
        }
    }

    private func scrolled(to offset: CGFloat) {
        let delta = offset - lastOffset
        lastOffset = offset
        guard abs(delta) > 6 else { return }
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
