import SwiftData
import SwiftUI

struct SearchView: View {
    let tab: Tab
    let dismiss: () -> Void

    @Environment(TabStore.self) private var tabs
    @Environment(Settings.self) private var settings
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \HistoryEntry.visitedAt, order: .reverse) private var history: [HistoryEntry]
    @State private var text = ""
    @State private var suggestions: [String] = []
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Rectangle().fill(Palette.background.opacity(0.55)).ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if trimmed.isEmpty {
                            recents
                        } else {
                            results
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                bottom
            }
        }
        .onAppear {
            text = tab.url?.absoluteString ?? ""
        }
        .task {
            try? await Task.sleep(for: .milliseconds(120))
            focused = true
        }
        .task(id: text) {
            guard settings.showsSuggestions, !trimmed.isEmpty else {
                suggestions = []
                return
            }
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            let found = await SuggestionService.fetch(trimmed, engine: settings.searchEngine)
            guard !Task.isCancelled else { return }
            suggestions = found
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Cancel", action: dismiss)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var recents: some View {
        let saved = bookmarks.prefix(4).map { (title: $0.title, url: $0.url, symbol: "star.fill") }
        let visited = tab.isPrivate ? [] : history.prefix(6).map { (title: $0.title, url: $0.url, symbol: "clock") }
        let combined = Array((saved + visited).prefix(8))
        if combined.isEmpty {
            EmptyState(emoji: Emoji.monocle, title: "Type a search or a website address")
                .padding(.vertical, 20)
        } else {
            ForEach(Array(combined.enumerated()), id: \.offset) { _, item in
                if let url = item.url {
                    row(symbol: item.symbol, title: item.title.isEmpty ? url.displayHost : item.title, subtitle: url.displayHost) {
                        open(url)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        if let direct = SearchEngine.directURL(trimmed) {
            row(symbol: "globe", title: String(localized: "Open \(direct.displayHost)"), subtitle: direct.absoluteString) {
                open(direct)
            }
        }
        row(symbol: "magnifyingglass", title: trimmed, subtitle: String(localized: "Search")) {
            submit()
        }
        ForEach(suggestions.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }, id: \.self) { suggestion in
            row(symbol: "magnifyingglass", title: suggestion, subtitle: nil) {
                text = suggestion
                submit()
            }
        }
        ForEach(Array(matches.enumerated()), id: \.offset) { _, item in
            if let url = item.url {
                row(symbol: item.symbol, title: item.title.isEmpty ? url.displayHost : item.title, subtitle: url.displayHost) {
                    open(url)
                }
            }
        }
    }

    private var matches: [(title: String, url: URL?, symbol: String)] {
        let needle = trimmed.lowercased()
        let saved = bookmarks
            .filter { $0.title.lowercased().contains(needle) || $0.urlString.lowercased().contains(needle) }
            .prefix(3)
            .map { (title: $0.title, url: $0.url, symbol: "star.fill") }
        let visited = tab.isPrivate ? [] : history
            .filter { $0.title.lowercased().contains(needle) || $0.urlString.lowercased().contains(needle) }
            .prefix(3)
            .map { (title: $0.title, url: $0.url, symbol: "clock") }
        return Array(saved) + Array(visited)
    }

    private func row(symbol: String, title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 34)
                        .background(Color.accentColor.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let subtitle {
                            Text(verbatim: subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                text = title
            } label: {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private var bottom: some View {
        VStack(spacing: 4) {
            grabber
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Search or enter address", text: $text)
                        .focused($focused)
                        .submitLabel(.go)
                        .onSubmit(submit)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.webSearch)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .glassEffect(.regular, in: .capsule)
                if !trimmed.isEmpty {
                    SearchGoButton(action: submit)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.25), value: trimmed.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    /// Drag the handle up to bring up the keyboard and down to hide it.
    private var grabber: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.55))
            .frame(width: 46, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 6).onEnded { value in
                    if value.translation.height < -12 {
                        focused = true
                    } else if value.translation.height > 12 {
                        if focused {
                            focused = false
                        } else {
                            dismiss()
                        }
                    }
                }
            )
    }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        tabs.submit(trimmed, in: tab)
        dismiss()
    }

    private func open(_ url: URL) {
        tab.load(url)
        dismiss()
    }
}
