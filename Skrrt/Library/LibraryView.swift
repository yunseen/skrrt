import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \HistoryEntry.visitedAt, order: .reverse) private var history: [HistoryEntry]
    @State private var mode: Mode = .bookmarks
    @State private var query = ""

    let open: (URL) -> Void

    var body: some View {
        NavigationStack {
            list
                .navigationTitle(mode.title)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "Search")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .principal) {
                        Picker("Library", selection: $mode.animation(.smooth)) {
                            ForEach(Mode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                    if mode == .history && !history.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Clear", role: .destructive) { clearHistory() }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var list: some View {
        switch mode {
        case .bookmarks:
            if filteredBookmarks.isEmpty {
                ContentUnavailableView("No Bookmarks", systemImage: "star", description: Text("Saved pages appear here."))
            } else {
                List {
                    ForEach(filteredBookmarks) { bookmark in
                        row(title: bookmark.title, url: bookmark.url)
                    }
                    .onDelete { offsets in
                        offsets.map { filteredBookmarks[$0] }.forEach(context.delete)
                    }
                }
            }
        case .history:
            if filteredHistory.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Visited pages appear here."))
            } else {
                List {
                    ForEach(filteredHistory) { entry in
                        row(title: entry.title, url: entry.url)
                    }
                    .onDelete { offsets in
                        offsets.map { filteredHistory[$0] }.forEach(context.delete)
                    }
                }
            }
        }
    }

    private func row(title: String, url: URL?) -> some View {
        Button {
            guard let url else { return }
            open(url)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? (url?.displayHost ?? "") : title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(url?.displayHost ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .concealed()
        }
    }

    private var filteredBookmarks: [Bookmark] {
        guard !query.isEmpty else { return bookmarks }
        return bookmarks.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.urlString.localizedCaseInsensitiveContains(query) }
    }

    private var filteredHistory: [HistoryEntry] {
        guard !query.isEmpty else { return history }
        return history.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.urlString.localizedCaseInsensitiveContains(query) }
    }

    private func clearHistory() {
        try? context.delete(model: HistoryEntry.self)
    }

    private enum Mode: String, CaseIterable, Identifiable {
        case bookmarks
        case history

        var id: String { rawValue }

        var title: String {
            switch self {
            case .bookmarks: "Bookmarks"
            case .history: "History"
            }
        }
    }
}
