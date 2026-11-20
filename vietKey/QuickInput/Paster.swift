import AppKit
import ApplicationServices
import Carbon

enum Paster {
    /// Value of kAXTrustedCheckOptionPrompt, which Swift 6 can't read as a global.
    private static let trustPromptOption = "AXTrustedCheckOptionPrompt"

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestTrust() {
        let options = [trustPromptOption: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func paste(withControl: Bool) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let flags: CGEventFlags = withControl ? .maskControl : .maskCommand
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.v, keyDown: keyDown)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
    }
}
