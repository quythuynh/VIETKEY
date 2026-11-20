import AppKit
import InputMethodKit
import VietEngine

extension VKInputController {
    @objc func selectInputMethod(_ sender: Any?) {
        MainActor.assumeIsolated {
            guard let raw = IMMenu.item(from: sender)?.representedObject as? String,
                  let kind = InputMethodKind(rawValue: raw) else { return }
            AppSettings.shared.inputMethod = kind
        }
    }

    @objc func toggleToneStyle(_ sender: Any?) {
        MainActor.assumeIsolated {
            let settings = AppSettings.shared
            settings.toneStyle = settings.toneStyle == .new ? .old : .new
        }
    }

    @objc func toggleSpellCheck(_ sender: Any?) {
        MainActor.assumeIsolated { AppSettings.shared.spellCheck.toggle() }
    }

    @objc func toggleMacros(_ sender: Any?) {
        MainActor.assumeIsolated { AppSettings.shared.macrosEnabled.toggle() }
    }

    @objc func toggleExcludeCurrentApp(_ sender: Any?) {
        let bundleID = client()?.bundleIdentifier()
        MainActor.assumeIsolated {
            guard let bundleID else { return }
            let settings = AppSettings.shared
            if let index = settings.excludedApps.firstIndex(of: bundleID) {
                settings.excludedApps.remove(at: index)
            } else {
                settings.excludedApps.append(bundleID)
            }
        }
    }

    @objc func openQuickInput(_ sender: Any?) {
        commitComposition(client())
        MainActor.assumeIsolated { QuickInputController.shared.show() }
    }

    @objc func openConverter(_ sender: Any?) {
        MainActor.assumeIsolated { SettingsWindowController.shared.show(tab: .converter) }
    }

    @objc func openSettings(_ sender: Any?) {
        MainActor.assumeIsolated { SettingsWindowController.shared.show(tab: .general) }
    }
}
