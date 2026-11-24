import SwiftUI

struct SearchSection: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Search Engine", selection: $settings.searchEngine) {
                ForEach(SearchEngineKind.allCases) { engine in
                    Text(engine.title).tag(engine)
                }
            }
            if settings.searchEngine == .custom {
                TextField("https://example.com/search?q=%s", text: $settings.customSearchURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Toggle("Search Suggestions", isOn: $settings.showsSuggestions)
        } header: {
            Text("Search")
        } footer: {
            if settings.searchEngine == .custom {
                Text("Put %s where the search words should go. Suggestions and results use the same engine.")
            } else {
                Text("Suggestions and results use the same engine.")
            }
        }
    }
}
