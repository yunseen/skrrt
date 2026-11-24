import SwiftUI

struct StartPage: View {
    let tab: Tab

    @Environment(Settings.self) private var settings
    @Environment(ShortcutStore.self) private var shortcuts
    @State private var appeared = false
    @State private var draft: ShortcutDraft?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                WallpaperView()
                if settings.showsMascots && !tab.isPrivate {
                    MascotScene()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                VStack(spacing: 0) {
                    Color.clear.frame(height: proxy.size.height * 0.46)
                    if tab.isPrivate {
                        privateHeader
                    } else {
                        ScrollView(showsIndicators: false) {
                            grid
                                .padding(.horizontal, 24)
                                .padding(.vertical, 6)
                        }
                    }
                    Spacer(minLength: Metrics.barHeight + 8)
                }
            }
        }
        .sheet(item: $draft) { draft in
            ShortcutEditor(draft: draft)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.9)) { appeared = true }
        }
    }

    private var labelColor: Color {
        settings.wallpaper == .ice ? Color.black.opacity(0.72) : Color.white.opacity(0.9)
    }

    private var privateHeader: some View {
        VStack(spacing: 14) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text("Private Tab")
                .font(.title2.weight(.bold))
                .foregroundStyle(labelColor)
            Text("History and website data are not saved.")
                .font(.subheadline)
                .foregroundStyle(labelColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1 : 0)
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: max(3, min(5, settings.tileColumns)))
        return LazyVGrid(columns: columns, spacing: 18) {
            ForEach(Array(shortcuts.items.enumerated()), id: \.element.id) { index, shortcut in
                tile(shortcut)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.smooth(duration: 0.6).delay(0.1 + Double(min(index, 12)) * 0.04), value: appeared)
            }
            addTile
                .opacity(appeared ? 1 : 0)
        }
    }

    private var tileShape: AnyShape {
        settings.tileShape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func tile(_ shortcut: Shortcut) -> some View {
        Button {
            if let url = shortcut.url {
                tab.load(url)
            }
        } label: {
            VStack(spacing: 8) {
                icon(shortcut)
                    .frame(width: 60, height: 60)
                    .glassEffect(.regular, in: tileShape)
                if settings.showsTileTitles {
                    Text(verbatim: shortcut.title)
                        .font(.caption)
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PressStyle())
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                draft = ShortcutDraft(existing: shortcut)
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                withAnimation(.smooth) { shortcuts.remove(shortcut) }
            }
        }
    }

    private var addTile: some View {
        Button {
            draft = ShortcutDraft(existing: nil)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(labelColor)
                    .frame(width: 60, height: 60)
                    .glassEffect(.regular, in: tileShape)
                if settings.showsTileTitles {
                    Text("Add")
                        .font(.caption)
                        .foregroundStyle(labelColor.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PressStyle())
    }

    @ViewBuilder
    private func icon(_ shortcut: Shortcut) -> some View {
        if let image = shortcuts.icon(for: shortcut) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        } else if let asset = shortcut.asset {
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Text(verbatim: String(shortcut.title.prefix(1)).uppercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }
}

struct ShortcutDraft: Identifiable {
    let id = UUID()
    let existing: Shortcut?
}

struct ShortcutEditor: View {
    let draft: ShortcutDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(ShortcutStore.self) private var shortcuts
    @State private var address = ""
    @State private var title = ""
    @State private var icon: UIImage?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        preview
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: title.isEmpty ? (IconFetcher.normalize(address)?.displayHost ?? "") : title)
                                .font(.headline)
                                .lineLimit(1)
                            if isLoading {
                                Text("Looking for the logo…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    TextField("Website address", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Name (optional)", text: $title)
                } footer: {
                    Text("The logo is found automatically from the website.")
                }
            }
            .navigationTitle(draft.existing == nil ? "New Shortcut" : "Edit Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(IconFetcher.normalize(address) == nil)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let existing = draft.existing {
                address = existing.urlString
                title = existing.title
                icon = shortcuts.icon(for: existing)
            }
        }
        .task(id: address) {
            guard let url = IconFetcher.normalize(address) else {
                if draft.existing == nil { icon = nil }
                return
            }
            if let existing = draft.existing, existing.urlString == url.absoluteString { return }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            isLoading = true
            let found = await IconFetcher.fetch(for: url)
            guard !Task.isCancelled else { return }
            isLoading = false
            icon = found
        }
    }

    @ViewBuilder
    private var preview: some View {
        Group {
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func save() {
        guard let url = IconFetcher.normalize(address) else { return }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = name.isEmpty ? url.displayHost : name
        if let existing = draft.existing {
            shortcuts.update(existing, title: finalTitle, url: url, icon: icon)
        } else {
            shortcuts.add(title: finalTitle, url: url, icon: icon)
        }
        dismiss()
    }
}
