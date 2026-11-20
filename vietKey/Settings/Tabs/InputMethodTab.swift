import SwiftUI
import VietEngine

struct InputMethodTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Input Method") {
                Picker("Input method", selection: $settings.inputMethod) {
                    ForEach(InputMethodKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                Picker("Tone placement", selection: $settings.toneStyle) {
                    ForEach(ToneStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }
            Section("Spelling") {
                Toggle("Restore keys when a word isn’t Vietnamese", isOn: $settings.spellCheck)
                Text("With Telex, typing “text” stays “text” instead of becoming “tẽt”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Output") {
                Picker("Show typed text", selection: $settings.outputMode) {
                    ForEach(OutputMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                Text("Replacing directly works like UniKey: Enter acts at once. Terminals always use underlined text; you can override this per app in the Apps tab.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
