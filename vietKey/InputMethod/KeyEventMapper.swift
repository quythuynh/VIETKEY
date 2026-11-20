import AppKit
import VietEngine

enum MappedKey: Equatable {
    case engine(KeyInput)
    case commitAndPass
}

enum KeyEventMapper {
    private static let escape: Character = "\u{1B}"

    static func map(_ event: NSEvent) -> MappedKey {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !flags.intersection([.command, .control, .option]).isEmpty {
            return .commitAndPass
        }
        if event.keyCode == KeyCode.delete {
            return .engine(.backspace)
        }
        guard let characters = event.characters, characters.count == 1, let character = characters.first,
              character != escape
        else { return .commitAndPass }

        // Arrows, F-keys and forward delete are in the private-use area.
        if let scalar = character.unicodeScalars.first, (0xF700...0xF8FF).contains(scalar.value) {
            return .commitAndPass
        }
        return .engine(.character(character))
    }
}
