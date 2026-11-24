import SwiftUI

struct ExtensionsView: View {
    @Environment(ExtensionStore.self) private var store
    @State private var editing: ScriptDraft?

    var body: some View {
        List {
            Section {
                ForEach(store.items.filter(\.isBuiltIn)) { item in
                    toggle(item)
                }
            } header: {
                Text("Built-in")
            }
            Section {
                ForEach(store.items.filter { !$0.isBuiltIn }) { item in
                    HStack {
                        Button {
                            editing = ScriptDraft(existing: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: item.name).foregroundStyle(.primary)
                                Text(verbatim: item.summary).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Toggle("", isOn: binding(item)).labelsHidden()
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.remove(item) }
                    }
                }
                Button {
                    editing = ScriptDraft(existing: nil)
                } label: {
                    Label("Add Script or Style", systemImage: "plus")
                }
            } header: {
                Text("My Extensions")
            } footer: {
                Text("Chrome and Safari extension packages cannot run in this browser. Scripts and styles you add here run on the sites you choose.")
            }
        }
        .navigationTitle("Extensions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { draft in
            ScriptEditor(draft: draft)
        }
    }

    private func toggle(_ item: SiteExtension) -> some View {
        Toggle(isOn: binding(item)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.name)
                Text(verbatim: item.summary).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func binding(_ item: SiteExtension) -> Binding<Bool> {
        Binding(
            get: { store.items.first { $0.id == item.id }?.isEnabled ?? false },
            set: { store.setEnabled(item.id, $0) }
        )
    }
}

struct ScriptDraft: Identifiable {
    let id = UUID()
    let existing: SiteExtension?
}

struct ScriptEditor: View {
    let draft: ScriptDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(ExtensionStore.self) private var store
    @State private var name = ""
    @State private var host = ""
    @State private var kind = SiteExtension.Kind.script
    @State private var code = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Website, for example example.com", text: $host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Type", selection: $kind) {
                        Text("Script").tag(SiteExtension.Kind.script)
                        Text("Style").tag(SiteExtension.Kind.style)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("Leave the website empty to run on every site.")
                }
                Section {
                    TextEditor(text: $code)
                        .font(.system(size: 14, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(minHeight: 200)
                } header: {
                    Text("Code")
                }
            }
            .navigationTitle(draft.existing == nil ? "New Extension" : "Edit Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let existing = draft.existing {
                name = existing.name
                host = existing.host == "*" ? "" : existing.host
                kind = existing.kind
                code = existing.code
            }
        }
    }

    private func save() {
        let cleanHost = host.trimmingCharacters(in: .whitespaces).lowercased()
        if var existing = draft.existing {
            existing.name = name
            existing.host = cleanHost.isEmpty ? "*" : cleanHost
            existing.summary = cleanHost.isEmpty ? String(localized: "All sites") : cleanHost
            existing.kind = kind
            existing.code = code
            store.update(existing)
        } else {
            store.add(name: name, host: cleanHost, kind: kind, code: code)
        }
        dismiss()
    }
}
