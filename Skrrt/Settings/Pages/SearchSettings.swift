import SwiftUI

struct SearchSettings: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                ForEach(SearchEngineKind.allCases) { engine in
                    Button {
                        settings.searchEngine = engine
                    } label: {
                        HStack(spacing: 12) {
                            EngineBadge(engine: engine)
                            Text(engine.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.searchEngine == engine {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if settings.searchEngine == .custom {
                    TextField("https://example.com/search?q=%s", text: $settings.customSearchURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Search Engine")
            } footer: {
                if settings.searchEngine == .custom {
                    Text("Put %s where the search words should go. Suggestions and results use the same engine.")
                } else {
                    Text("Suggestions and results use the same engine.")
                }
            }
            Section {
                Toggle(isOn: $settings.showsSuggestions) {
                    IconLabel("Search Suggestions", "text.magnifyingglass", Color(red: 0.039, green: 0.518, blue: 1))
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}
