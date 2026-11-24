import SwiftUI

struct StartPage: View {
    let tab: Tab

    @State private var appeared = false

    private let favorites: [Favorite] = [
        Favorite(letter: "G", title: "Google", url: "https://www.google.com"),
        Favorite(letter: "Y", title: "YouTube", url: "https://www.youtube.com"),
        Favorite(letter: "W", title: "Wikipedia", url: "https://www.wikipedia.org"),
        Favorite(letter: "G", title: "GitHub", url: "https://github.com"),
        Favorite(letter: "R", title: "Reddit", url: "https://www.reddit.com"),
        Favorite(letter: "M", title: "Maps", url: "https://maps.google.com"),
        Favorite(letter: "N", title: "News", url: "https://news.google.com"),
        Favorite(letter: "M", title: "Mail", url: "https://mail.google.com")
    ]

    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 30) {
                Spacer()
                header
                if !tab.isPrivate {
                    grid
                }
                Spacer()
                Spacer(minLength: Metrics.barHeight)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.9)) { appeared = true }
        }
    }

    private var header: some View {
        VStack(spacing: 18) {
            if tab.isPrivate {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(Palette.blue)
                Text("Private Tab")
                    .font(.title2.weight(.bold))
                Text("History and website data are not saved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image("LogoMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(Palette.blue)
                Image("Wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 26)
                    .foregroundStyle(.primary)
            }
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
            ForEach(Array(favorites.enumerated()), id: \.offset) { index, favorite in
                tile(favorite)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.smooth(duration: 0.6).delay(0.15 + Double(index) * 0.04), value: appeared)
            }
        }
    }

    private func tile(_ favorite: Favorite) -> some View {
        Button {
            if let url = URL(string: favorite.url) {
                tab.load(url)
            }
        } label: {
            VStack(spacing: 8) {
                Text(verbatim: favorite.letter)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(width: 60, height: 60)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                Text(favorite.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PressStyle())
    }

    private struct Favorite {
        let letter: String
        let title: LocalizedStringKey
        let url: String
    }
}
