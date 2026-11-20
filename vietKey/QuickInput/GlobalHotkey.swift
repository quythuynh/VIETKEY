import AppKit
import Carbon
import os

final class GlobalHotkey {
    static let shared = GlobalHotkey()

    var action: (() -> Void)?

    private static let signature: OSType = 0x564B_4559  // "VKEY"

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register(_ hotkey: Hotkey) {
        unregister()
        guard let keyCode = hotkey.keyCode else { return }
        installHandlerIfNeeded()

        let id = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(UInt32(keyCode), Self.carbonModifiers(hotkey.modifierFlags), id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            Log.app.error("RegisterEventHotKey failed: \(status)")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let hotkey = Unmanaged<GlobalHotkey>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated {
                hotkey.action?()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    }

    private static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }
}
