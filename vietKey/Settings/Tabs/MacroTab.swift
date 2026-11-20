import SwiftUI
import UniformTypeIdentifiers
import VietEngine

struct MacroTab: View {
    @Bindable var settings: AppSettings

    @State private var selection: Set<String> = []
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var errorMessage: String?

    private static let exportFileName = "VIET-macros.txt"

    private struct Row: Identifiable {
        let key: String
        let value: String
        var id: String { key }
    }

    private var rows: [Row] {
        settings.macros.keys.sorted().map { Row(key: $0, value: settings.macros[$0] ?? "") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Expand macros when a word ends", isOn: $settings.macrosEnabled)

            Table(rows, selection: $selection) {
                TableColumn("Abbreviation", value: \.key)
                    .width(min: 80, ideal: 120)
                TableColumn("Expands to", value: \.value)
            }

            HStack {
                TextField("Abbreviation", text: $newKey)
                    .frame(width: 120)
                TextField("Expands to", text: $newValue)
                Button("Add") { add() }
                    .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty || newValue.isEmpty)
            }

            HStack {
                Button("Remove") {
                    for key in selection { settings.macros[key] = nil }
                    selection = []
                }
                .disabled(selection.isEmpty)
                Spacer()
                Button("Import…") { importFile() }
                Button("Export…") { exportFile() }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
    }

    private func add() {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        settings.macros[key] = newValue
        newKey = ""
        newValue = ""
    }

    private func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let entries = MacroFileFormat.parse(try String(contentsOf: url, encoding: .utf8))
            settings.macros.merge(entries) { _, imported in imported }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = Self.exportFileName
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try MacroFileFormat.serialize(settings.macros).write(to: url, atomically: true, encoding: .utf8)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
