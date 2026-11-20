import AppKit
import SwiftUI

struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey
    var allowsModifierOnly = true
    var defaultHotkey: Hotkey = .default

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var pressedModifiers: NSEvent.ModifierFlags = []

    var body: some View {
        HStack {
            Text(isRecording ? String(localized: "Press shortcut…") : hotkey.displayString)
                .monospaced()
                .frame(minWidth: 110)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 5).fill(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12)))
            Button(isRecording ? "Cancel" : "Record") {
                isRecording ? stop() : start()
            }
            Button("Reset") { hotkey = defaultHotkey }
                .disabled(hotkey == defaultHotkey)
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        pressedModifiers = []
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            record(event)
            return nil
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
    }

    private func record(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(Hotkey.relevantModifiers)
        switch event.type {
        case .flagsChanged:
            if flags.isEmpty {
                let count = [NSEvent.ModifierFlags.control, .option, .shift, .command].filter(pressedModifiers.contains).count
                if allowsModifierOnly && count >= 2 {
                    hotkey = Hotkey(keyCode: nil, modifiers: pressedModifiers.rawValue, keyLabel: "")
                    stop()
                }
                pressedModifiers = []
            } else {
                pressedModifiers.formUnion(flags)
            }
        case .keyDown:
            if flags.isEmpty {
                if event.keyCode == KeyCode.escape { stop() } else { NSSound.beep() }
                return
            }
            let label = event.charactersIgnoringModifiers?.uppercased() ?? ""
            hotkey = Hotkey(keyCode: event.keyCode, modifiers: flags.rawValue, keyLabel: label)
            stop()
        default:
            break
        }
    }
}
