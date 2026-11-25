import PhotosUI
import SwiftUI

struct HomeSettings: View {
    @Environment(Settings.self) private var settings
    @Environment(ShortcutStore.self) private var shortcuts
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var confirmsReset = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(WallpaperStyle.allCases) { style in
                            card(style)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("Wallpaper")
            }

            if settings.wallpaper == .photo {
                Section {
                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        IconLabel("Choose Photo", "photo.fill", Color(red: 0.62, green: 0.45, blue: 1))
                    }
                    Button(role: .destructive) {
                        WallpaperStorage.remove()
                        settings.photoRevision += 1
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        IconLabel("Blur", "drop.fill", Color(red: 0.039, green: 0.518, blue: 1))
                        Spacer()
                        Text(verbatim: "\(Int(settings.wallpaperBlur))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $settings.wallpaperBlur, in: 0...40, step: 1)
                }
                .padding(.vertical, 2)
                Toggle(isOn: $settings.animatesWallpaper) {
                    IconLabel("Animate Wallpaper", "sparkles", Color(red: 1, green: 0.58, blue: 0.15))
                }
            }

            Section {
                HStack(spacing: 12) {
                    ForEach(TileShape.allCases) { shape in
                        ChoiceCard(isSelected: settings.tileShape == shape) {
                            settings.tileShape = shape
                        } content: {
                            VStack(spacing: 8) {
                                shapePreview(shape)
                                Text(shape.title)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                Toggle(isOn: $settings.showsTileTitles) {
                    IconLabel("Show Tile Names", "textformat", Color(red: 0.2, green: 0.78, blue: 0.45))
                }
                Stepper(value: $settings.tileColumns, in: 3...5) {
                    HStack {
                        IconLabel("Columns", "rectangle.split.3x1.fill", Color(red: 0.62, green: 0.45, blue: 1))
                        Spacer()
                        Text(verbatim: "\(settings.tileColumns)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Shortcuts")
            } footer: {
                Text("Touch and hold a shortcut on the home screen to edit or delete it. Tap Add to create your own and the logo is found automatically.")
            }

            Section {
                Button(role: .destructive) {
                    confirmsReset = true
                } label: {
                    Label("Reset Shortcuts", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Home Screen")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self), WallpaperStorage.save(data) else { return }
                settings.wallpaper = .photo
                settings.photoRevision += 1
            }
        }
        .confirmationDialog("Restore the default shortcuts?", isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("Reset Shortcuts", role: .destructive) {
                shortcuts.resetToDefaults()
            }
        }
    }

    private func card(_ style: WallpaperStyle) -> some View {
        Button {
            settings.wallpaper = style
        } label: {
            VStack(spacing: 8) {
                preview(style)
                    .frame(width: 88, height: 154)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(settings.wallpaper == style ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: settings.wallpaper == style ? 3 : 1)
                    }
                Text(style.title)
                    .font(.footnote.weight(settings.wallpaper == style ? .semibold : .regular))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func preview(_ style: WallpaperStyle) -> some View {
        switch style {
        case .curtain:
            CurtainWallpaper(animated: false)
        case .ice:
            IceWallpaper(animated: false)
        case .aurora:
            AuroraBackground()
        case .photo:
            ZStack {
                Color.primary.opacity(0.08)
                if WallpaperStorage.load() != nil {
                    PhotoWallpaper(animated: false, revision: settings.photoRevision)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func shapePreview(_ shape: TileShape) -> some View {
        let fill = Color.accentColor.gradient
        switch shape {
        case .squircle:
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill).frame(width: 44, height: 44)
        case .circle:
            Circle().fill(fill).frame(width: 44, height: 44)
        }
    }
}
