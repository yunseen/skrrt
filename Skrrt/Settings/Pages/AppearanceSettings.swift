import SwiftUI

struct AppearanceSettings: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                HStack(spacing: 12) {
                    ForEach(Appearance.allCases) { appearance in
                        ChoiceCard(isSelected: settings.appearance == appearance) {
                            settings.appearance = appearance
                        } content: {
                            VStack(spacing: 8) {
                                Image(systemName: symbol(appearance))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                                Text(appearance.title)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } header: {
                Text("Theme")
            }

            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 14) {
                    ForEach(AccentChoice.allCases.filter { $0 != .custom }) { choice in
                        Button {
                            settings.accent = choice
                        } label: {
                            Circle()
                                .fill((choice.preset ?? Palette.blue).gradient)
                                .frame(width: 38, height: 38)
                                .overlay {
                                    if settings.accent == choice {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                ColorPicker(selection: customColor, supportsOpacity: false) {
                    IconLabel("Custom Color", "eyedropper", Color(red: 1, green: 0.36, blue: 0.62))
                }
            } header: {
                Text("Accent Color")
            }

            Section {
                ForEach(DarkPages.allCases) { option in
                    Button {
                        settings.darkPages = option
                    } label: {
                        HStack {
                            Text(option.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.darkPages == option {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Dark Pages")
            } footer: {
                Text("Off keeps websites in their normal colors. Match App and Always ask them for a dark version.")
            }

            Section {
                Toggle(isOn: $settings.smartDark) {
                    IconLabel("Smart Dark Mode", "moon.stars.fill", Color(red: 0.62, green: 0.45, blue: 1))
                }
            } footer: {
                Text("Darkens pages that have no dark theme of their own and keeps photos and video in their real colors.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func symbol(_ appearance: Appearance) -> String {
        switch appearance {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { Color(hex: settings.customAccentHex) ?? Palette.blue },
            set: { newValue in
                settings.customAccentHex = newValue.hexString
                settings.accent = .custom
            }
        )
    }
}
