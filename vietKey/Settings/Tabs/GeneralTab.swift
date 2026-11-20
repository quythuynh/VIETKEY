import SwiftUI

struct GeneralTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Installation") {
                InstallationStatusView()
            }
            Section("Switch Vietnamese / English") {
                LabeledContent("Shortcut") {
                    HotkeyRecorder(hotkey: $settings.hotkey)
                }
                Toggle("Remember Vietnamese / English for each app", isOn: $settings.rememberModePerApp)
                Text("You can also pick “Vietnamese” or “English” of VIET from the input menu in the menu bar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Quick Input") {
                Text("For TeamViewer, AnyDesk and virtual machines: press the shortcut, type Vietnamese, then Enter to paste it into the app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent("Shortcut") {
                    HotkeyRecorder(hotkey: $settings.quickInputHotkey, allowsModifierOnly: false, defaultHotkey: .quickInputDefault)
                }
                Toggle("Paste with ⌃V instead of ⌘V (remote Windows computers)", isOn: $settings.pasteWithControl)
                AutoPasteStatusView()
            }
        }
        .formStyle(.grouped)
    }
}

private struct AutoPasteStatusView: View {
    @State private var isTrusted = Paster.isTrusted

    var body: some View {
        if isTrusted {
            Label("Automatic paste is on.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Without Accessibility access, the text is copied and you paste it yourself.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Allow Automatic Paste…") { Paster.requestTrust() }
                    Button("Check Again") { isTrusted = Paster.isTrusted }
                }
            }
        }
    }
}

private struct InstallationStatusView: View {
    @State private var isInstalled = InputSourceInstaller.isInstalled
    @State private var isEnabled = InputSourceInstaller.isEnabled
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !InputSourceInstaller.isRunningFromInstallLocation {
                Text("VIET must be installed in your Input Methods folder before you can type with it.")
                Button("Install VIET") { install() }
                    .buttonStyle(.borderedProminent)
            } else if !isEnabled {
                Text("VIET is installed but not enabled as an input source.")
                Button("Enable VIET") {
                    InputSourceInstaller.enable()
                    isEnabled = InputSourceInstaller.isEnabled
                }
            } else {
                Label("VIET is installed and enabled.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if isInstalled && !InputSourceInstaller.isRunningFromInstallLocation {
                Text("Installed. Choose VIET from the input menu in the menu bar, then close this window.")
                    .foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
            Button("Open Keyboard Settings…") { InputSourceInstaller.openKeyboardSettings() }
        }
    }

    private func install() {
        do {
            try InputSourceInstaller.install()
            isInstalled = true
            isEnabled = InputSourceInstaller.isEnabled
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // This copy shares the bundle ID with the installed one and would keep it from launching.
        let alert = NSAlert()
        alert.messageText = String(localized: "VIET is installed")
        alert.informativeText = String(localized: "Choose “VIET” from the input menu in the menu bar. This installer will now quit.")
        alert.runModal()
        NSApp.terminate(nil)
    }
}
