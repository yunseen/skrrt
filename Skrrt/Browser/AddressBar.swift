import SwiftUI

struct AddressBar: View {
    let tab: Tab

    @Environment(TabStore.self) private var tabs
    @State private var text = ""
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: leadingSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tab.url != nil && tab.isSecure ? Palette.blue : Color.secondary)
            field
            trailing
        }
        .padding(.horizontal, 18)
        .frame(height: tab.isCompact ? 40 : 52)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottomLeading) { progressBar }
        .animation(.smooth(duration: 0.3), value: isEditing)
    }

    @ViewBuilder
    private var field: some View {
        if isEditing {
            TextField("Search or enter address", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .focused($isFocused)
                .onSubmit(submit)
                .task {
                    try? await Task.sleep(for: .milliseconds(60))
                    isFocused = true
                }
        } else {
            Button(action: begin) {
                Group {
                    if let url = tab.url {
                        Text(verbatim: url.displayHost)
                    } else {
                        Text("Search or enter address")
                    }
                }
                .font(.system(size: tab.isCompact ? 14 : 16, weight: .medium))
                .foregroundStyle(tab.url == nil ? .secondary : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .concealed()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isEditing {
            Button("Cancel", action: cancel)
                .font(.system(size: 15, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(Palette.blue)
        } else if tab.url != nil && !tab.isCompact {
            Button {
                if tab.isLoading { tab.stop() } else { tab.reload() }
            } label: {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if tab.isLoading && !isEditing {
            Capsule()
                .fill(Palette.blue)
                .frame(height: 3)
                .scaleEffect(x: max(tab.progress, 0.06), anchor: .leading)
                .animation(.smooth(duration: 0.3), value: tab.progress)
                .padding(.horizontal, 26)
                .padding(.bottom, 4)
                .transition(.opacity)
        }
    }

    private var leadingSymbol: String {
        guard tab.url != nil else { return "magnifyingglass" }
        return tab.isSecure ? "lock.fill" : "exclamationmark.triangle.fill"
    }

    private func begin() {
        if tab.isCompact {
            tab.expand()
            return
        }
        text = tab.url?.absoluteString ?? ""
        isEditing = true
    }

    private func cancel() {
        isFocused = false
        isEditing = false
    }

    private func submit() {
        tabs.submit(text, in: tab)
        cancel()
    }
}
