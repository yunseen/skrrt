import SwiftUI
import WebKit

/// Shows the cookies a site has stored in this browser and lets you remove them one by one or all at once.
struct CookieManagerView: View {
    let tab: Tab

    @State private var cookies: [HTTPCookie] = []
    @State private var isLoading = true
    @State private var selected: HTTPCookie?
    @State private var confirmsClearing = false

    private var host: String {
        (tab.url?.host ?? "").replacingOccurrences(of: "www.", with: "")
    }

    private var store: WKHTTPCookieStore {
        tab.webView.configuration.websiteDataStore.httpCookieStore
    }

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if cookies.isEmpty {
                ContentUnavailableView(
                    "No Cookies",
                    systemImage: "circle.hexagongrid",
                    description: Text("This site has not stored any cookies.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(cookies, id: \.self) { cookie in
                        Button {
                            selected = cookie
                        } label: {
                            row(cookie)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                Task { await delete(cookie) }
                            }
                        }
                    }
                } header: {
                    Text("\(cookies.count) cookies")
                } footer: {
                    Text("Tap a cookie to see it. Swipe to delete. Deleting a cookie of a sign-in signs you out of the site.")
                }
            }
        }
        .navigationTitle("Cookies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task { await load() }
                    }
                    if !cookies.isEmpty {
                        Button("Delete All", systemImage: "trash", role: .destructive) {
                            confirmsClearing = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task { await load() }
        .sheet(item: $selected) { cookie in
            CookieDetailView(cookie: cookie) {
                Task {
                    await delete(cookie)
                    selected = nil
                }
            }
        }
        .confirmationDialog("Delete all cookies of this site?", isPresented: $confirmsClearing, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                Task {
                    for cookie in cookies { await store.deleteCookie(cookie) }
                    await load()
                }
            }
        }
    }

    private func row(_ cookie: HTTPCookie) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: cookie.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(verbatim: cookie.domain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if cookie.isSecure {
                Image(systemName: "lock.fill").font(.caption).foregroundStyle(.green)
            }
            if cookie.isHTTPOnly {
                Image(systemName: "network").font(.caption).foregroundStyle(.blue)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func load() async {
        isLoading = true
        cookies = await Self.cookies(for: host, in: tab)
        isLoading = false
    }

    private func delete(_ cookie: HTTPCookie) async {
        await store.deleteCookie(cookie)
        await load()
    }

    /// The cookies a request to this host would carry, sorted by name.
    static func cookies(for host: String, in tab: Tab) async -> [HTTPCookie] {
        guard !host.isEmpty else { return [] }
        let all = await tab.webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        return all
            .filter { cookie in
                var domain = cookie.domain.lowercased()
                if domain.hasPrefix(".") { domain.removeFirst() }
                return host == domain || host.hasSuffix("." + domain)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

extension HTTPCookie: @retroactive Identifiable {
    public var id: String { "\(domain)|\(path)|\(name)" }
}

struct CookieDetailView: View {
    let cookie: HTTPCookie
    let delete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Name", value: cookie.name)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Value")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(verbatim: cookie.value)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    LabeledContent("Domain", value: cookie.domain)
                    LabeledContent("Path", value: cookie.path)
                    LabeledContent("Expires") {
                        if let date = cookie.expiresDate {
                            Text(date, style: .date)
                        } else {
                            Text("End of session")
                        }
                    }
                }
                Section {
                    LabeledContent("Secure") { Text(cookie.isSecure ? "Yes" : "No") }
                    LabeledContent("Hidden from scripts") { Text(cookie.isHTTPOnly ? "Yes" : "No") }
                }
                Section {
                    Button("Copy Value", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = cookie.value
                    }
                    Button("Delete Cookie", systemImage: "trash", role: .destructive) {
                        delete()
                    }
                }
            }
            .navigationTitle(cookie.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
