import AppKit

/// Modifier-only hotkeys (⌃⇧) fire on release, unless another key was pressed meanwhile.
struct HotkeyMonitor {
    private var armed = false

    mutating func handle(_ event: NSEvent, hotkey: Hotkey) -> Bool {
        let flags = event.modifierFlags.intersection(Hotkey.relevantModifiers)
        switch event.type {
        case .flagsChanged:
            guard hotkey.keyCode == nil else { return false }
            if flags == hotkey.modifierFlags {
                armed = true
            } else if flags.isEmpty {
                defer { armed = false }
                return armed
            } else if !flags.isSubset(of: hotkey.modifierFlags) {
                armed = false
            }
            return false

        case .keyDown:
            armed = false
            guard let keyCode = hotkey.keyCode else { return false }
            return keyCode == event.keyCode && flags == hotkey.modifierFlags

        default:
            return false
        }
    }
}
