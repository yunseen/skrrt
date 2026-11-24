import SwiftUI

struct AppearanceSection: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(Appearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            swatches
            ColorPicker("Custom Color", selection: customColor, supportsOpacity: false)
            Picker("Dark Pages", selection: $settings.darkPages) {
                ForEach(DarkPages.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Dark Pages asks websites for their dark version, including search results.")
        }
    }

    private var swatches: some View {
        HStack(spacing: 12) {
            ForEach(AccentChoice.allCases.filter { $0 != .custom }) { choice in
                Button {
                    settings.accent = choice
                } label: {
                    Circle()
                        .fill(choice.preset ?? Palette.blue)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if settings.accent == choice {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
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
