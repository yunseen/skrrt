import SwiftUI

struct TabCard: View {
    let tab: Tab
    let isSelected: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        Button(action: select) {
            Color.clear
                .frame(height: 230)
                .overlay(alignment: .top) { preview }
                .clipped()
                .overlay(alignment: .bottom) { caption }
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                        .strokeBorder(isSelected ? Palette.blue : Color.primary.opacity(0.12), lineWidth: isSelected ? 3 : 1)
                }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .padding(8)
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
                    .foregroundStyle(Palette.blue.opacity(0.8))
            }
            .frame(height: 230)
        }
    }

    private var caption: some View {
        HStack(spacing: 6) {
            if tab.isPrivate {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.blue)
            }
            Text(tab.displayTitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .concealed()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 0))
    }
}
