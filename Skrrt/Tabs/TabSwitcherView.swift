import SwiftUI

struct TabSwitcherView: View {
    let dismiss: () -> Void

    @Environment(TabStore.self) private var tabs
    @State private var showsPrivate = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var visible: [Tab] {
        tabs.tabs.filter { $0.isPrivate == showsPrivate }
    }

    var body: some View {
        ZStack {
            AuroraBackground().ignoresSafeArea()
            ScrollView {
                if visible.isEmpty {
                    ContentUnavailableView(
                        showsPrivate ? "No Private Tabs" : "No Tabs",
                        systemImage: showsPrivate ? "eye.slash" : "square.on.square"
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(visible) { tab in
                            TabCard(
                                tab: tab,
                                isSelected: tab.id == tabs.selectedID,
                                select: {
                                    tabs.select(tab)
                                    dismiss()
                                },
                                close: {
                                    withAnimation(.smooth) { tabs.close(tab) }
                                }
                            )
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .safeAreaInset(edge: .top, spacing: 8) { header }
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        }
    }

    private var header: some View {
        Picker("Mode", selection: $showsPrivate.animation(.smooth)) {
            Text("Tabs").tag(false)
            Text("Private").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 60)
    }

    private var footer: some View {
        GlassEffectContainer(spacing: 14) {
            HStack {
                GlassIconButton(symbol: "plus") {
                    tabs.open(isPrivate: showsPrivate)
                    dismiss()
                }
                Spacer()
                Button("Done", action: dismiss)
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}
