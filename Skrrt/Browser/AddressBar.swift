import SwiftUI

struct AddressBar: View {
    let tab: Tab
    let openSearch: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: leadingSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tab.url != nil && tab.isSecure ? Color.accentColor : Color.secondary)
            field
            trailing
        }
        .padding(.horizontal, 18)
        .frame(height: tab.isCompact ? 40 : 52)
        .glassEffect(.regular, in: .capsule)
        .overlay(alignment: .bottomLeading) { progressBar }
        .simultaneousGesture(
            DragGesture(minimumDistance: 14).onEnded { value in
                if value.translation.height < -20 { begin() }
            }
        )
    }

    private var field: some View {
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

    @ViewBuilder
    private var trailing: some View {
        if tab.url != nil && !tab.isCompact {
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
        if tab.isLoading {
            Capsule()
                .fill(Color.accentColor)
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
        openSearch()
    }
}
