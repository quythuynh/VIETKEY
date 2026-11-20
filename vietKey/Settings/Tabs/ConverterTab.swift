import AppKit
import SwiftUI
import VietCharset

struct ConverterTab: View {
    private enum StorageKey {
        static let source = "converter.source"
        static let target = "converter.target"
        static let stripTones = "converter.stripTones"
    }

    @AppStorage(StorageKey.source) private var source: Charset = .tcvn3
    @AppStorage(StorageKey.target) private var target: Charset = .unicode
    @AppStorage(StorageKey.stripTones) private var stripTones = false

    @State private var input = ""
    @State private var status: String?

    private var output: String {
        CharsetConverter.convert(input, from: source, to: target, stripTones: stripTones)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("From", selection: $source) {
                    ForEach(Charset.allCases) { Text($0.displayName).tag($0) }
                }
                Button {
                    swap(&source, &target)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .help("Swap")
                Picker("To", selection: $target) {
                    ForEach(Charset.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Toggle("Remove tones and marks", isOn: $stripTones)

            HStack(spacing: 10) {
                VStack(alignment: .leading) {
                    Text("Source").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $input)
                        .font(.body)
                        .border(.separator)
                }
                VStack(alignment: .leading) {
                    Text("Result").font(.caption).foregroundStyle(.secondary)
                    ScrollView {
                        Text(output)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .border(.separator)
                }
            }

            HStack {
                Button("Paste") {
                    input = NSPasteboard.general.string(forType: .string) ?? ""
                }
                Button("Copy Result") {
                    copy(output)
                    status = String(localized: "Result copied.")
                }
                .disabled(input.isEmpty)
                Spacer()
                Button("Convert Clipboard") { convertClipboard() }
                    .buttonStyle(.borderedProminent)
            }
            if let status {
                Text(status).font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private func convertClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            status = String(localized: "The clipboard has no text.")
            return
        }
        input = text
        copy(output)
        status = String(localized: "Clipboard converted.")
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
