import SwiftUI

struct TabCard: View {
    let tab: Tab
    let isSelected: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: select) {
                Color.clear
                    .frame(height: 230)
                    .overlay(alignment: .top) { preview }
                    .clipped()
                    .overlay(alignment: .bottom) { caption }
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: isSelected ? 3 : 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 40, height: 40)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .contentShape(Circle())
            }
            .buttonStyle(PressStyle())
            .padding(6)
            .zIndex(1)
            .accessibilityLabel(Text("Close Tab"))
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let image = tab.snapshot {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Palette.background
                Image("LogoMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56)
                    .foregroundStyle(Color.accentColor.opacity(0.8))
            }
            .frame(height: 230)
        }
    }

    private var caption: some View {
        HStack(spacing: 6) {
            if tab.isPrivate {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
            Group {
                if tab.displayTitle.isEmpty {
                    Text("New Tab")
                } else {
                    Text(verbatim: tab.displayTitle)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .concealed()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}
