import PhotosUI
import SwiftUI

struct HomeScreenSection: View {
    @Environment(Settings.self) private var settings
    @Environment(ShortcutStore.self) private var shortcuts
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var confirmsReset = false

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Wallpaper", selection: $settings.wallpaper) {
                ForEach(WallpaperStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            if settings.wallpaper == .photo {
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Blur")
                    Spacer()
                    Text(verbatim: "\(Int(settings.wallpaperBlur))")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.wallpaperBlur, in: 0...40, step: 1)
            }
            Toggle("Animate Wallpaper", isOn: $settings.animatesWallpaper)
            Toggle("Show Mascots", isOn: $settings.showsMascots)
            Picker("Tile Shape", selection: $settings.tileShape) {
                ForEach(TileShape.allCases) { shape in
                    Text(shape.title).tag(shape)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Show Tile Names", isOn: $settings.showsTileTitles)
            Stepper(value: $settings.tileColumns, in: 3...5) {
                Text("Columns: \(settings.tileColumns)")
            }
            Button("Reset Shortcuts", role: .destructive) {
                confirmsReset = true
            }
        } header: {
            Text("Home Screen")
        } footer: {
            Text("Touch and hold a shortcut on the home screen to edit or delete it. Tap Add to create your own and the logo is found automatically.")
        }
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
}
