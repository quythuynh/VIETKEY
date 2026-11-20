import Foundation

enum VIQRCodec {
    private static let letterMarks: [Character: Character] = ["\u{302}": "^", "\u{306}": "(", "\u{31B}": "+"]
    private static let toneMarks: [Character: Character] = [
        "\u{301}": "'", "\u{300}": "`", "\u{309}": "?", "\u{303}": "~", "\u{323}": ".",
    ]
    private static let vowels = Set("aeiouyAEIOUY")

    static func encode(_ text: String) -> String {
        var output = ""
        for character in text {
            switch character {
            case "đ": output += "dd"
            case "Đ": output += "DD"
            default:
                let scalars = String(character).decomposedStringWithCanonicalMapping.unicodeScalars
                guard let base = scalars.first, vowels.contains(Character(base)), scalars.count > 1 else {
                    output.append(character)
                    continue
                }
                // Canonical order puts the dot below before the circumflex; VIQR writes the letter mark first (e^.).
                let marks = scalars.dropFirst().map(Character.init)
                guard marks.allSatisfy({ letterMarks[$0] != nil || toneMarks[$0] != nil }) else {
                    output.append(character)
                    continue
                }
                output.unicodeScalars.append(base)
                output += String(marks.compactMap { letterMarks[$0] })
                output += String(marks.compactMap { toneMarks[$0] })
            }
        }
        return output
    }

    static func decode(_ text: String) -> String {
        let characters = Array(text)
        let letterMarkFor = Dictionary(uniqueKeysWithValues: letterMarks.map { ($1, $0) })
        let toneMarkFor = Dictionary(uniqueKeysWithValues: toneMarks.map { ($1, $0) })

        var output = ""
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if (character == "d" || character == "D"), index + 1 < characters.count,
               characters[index + 1] == "d" || characters[index + 1] == "D" {
                output.append(character == "d" ? "đ" : "Đ")
                index += 2
                continue
            }
            guard vowels.contains(character) else {
                output.append(character)
                index += 1
                continue
            }
            var composed = String(character)
            index += 1
            if index < characters.count, let mark = letterMarkFor[characters[index]],
               isValidLetterMark(characters[index], on: character) {
                composed.append(mark)
                index += 1
            }
            if index < characters.count, let tone = toneMarkFor[characters[index]] {
                composed.append(tone)
                index += 1
            }
            output += composed.precomposedStringWithCanonicalMapping
        }
        return output
    }

    private static func isValidLetterMark(_ mark: Character, on vowel: Character) -> Bool {
        let base = Character(vowel.lowercased())
        switch mark {
        case "^": return base == "a" || base == "e" || base == "o"
        case "(": return base == "a"
        case "+": return base == "o" || base == "u"
        default: return false
        }
    }
}
