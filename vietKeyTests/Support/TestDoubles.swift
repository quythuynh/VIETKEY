import AppKit
import Carbon
@testable import vietKey
import VietEngine

final class FakeModeSelector: InputModeSelecting {
    private(set) var selections: [Bool] = []

    func select(vietnamese: Bool) {
        selections.append(vietnamese)
    }
}

enum KeyEvents {
    static func key(_ character: Character, flags: NSEvent.ModifierFlags = []) -> NSEvent {
        let (characters, keyCode): (String, UInt16) = switch character {
        case "⌫": ("\u{7F}", KeyCode.delete)
        case "⏎": ("\r", KeyCode.returnKey)
        case " ": (" ", KeyCode.space)
        default: (String(character), UInt16(kVK_ANSI_A))
        }
        return NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0,
                                context: nil, characters: characters, charactersIgnoringModifiers: characters,
                                isARepeat: false, keyCode: keyCode)!
    }

    static func modifiers(_ flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .flagsChanged, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0,
                         context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 59)!
    }
}

func makeSettings() -> AppSettings {
    AppSettings(defaults: UserDefaults(suiteName: "vietKeyTests-\(UUID().uuidString)")!)
}
