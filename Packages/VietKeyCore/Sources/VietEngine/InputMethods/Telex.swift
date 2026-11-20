struct Telex: InputMethod {
    let extended: Bool

    func isWordKey(_ key: Character) -> Bool {
        if key.isASCII && key.isLetter { return true }
        return extended && Telex.bracketVowels[key] != nil
    }

    func canStartWord(_ key: Character) -> Bool {
        isWordKey(key)
    }

    func actions(for key: Character) -> [KeyAction] {
        switch key.lowercased() {
        case "s": return [.tone(.acute)]
        case "f": return [.tone(.grave)]
        case "r": return [.tone(.hook)]
        case "x": return [.tone(.tilde)]
        case "j": return [.tone(.dot)]
        case "z": return [.tone(.none)]
        case "a": return [.circumflex("a")]
        case "e": return [.circumflex("e")]
        case "o": return [.circumflex("o")]
        case "d": return [.stroke]
        case "w":
            let u = Letter(base: "u", mod: .horn, isUppercase: key.isUppercase, sourceKey: key)
            return [.hornOrBreve, .insert(u, requiresNoVowel: true)]
        default:
            if extended, let letter = Telex.bracketVowels[key] {
                return [.insert(letter, requiresNoVowel: false)]
            }
            return []
        }
    }

    func keys(for letter: Letter) -> [Character] {
        if let source = letter.sourceKey { return [source] }
        let base = letter.isUppercase ? Character(letter.base.uppercased()) : letter.base
        switch letter.mod {
        case .none: return [base]
        case .circumflex: return [base, letter.base]
        case .breve, .horn: return [base, "w"]
        case .stroke: return [base, "d"]
        }
    }

    func key(for tone: ToneMark) -> Character? {
        switch tone {
        case .none: nil
        case .acute: "s"
        case .grave: "f"
        case .hook: "r"
        case .tilde: "x"
        case .dot: "j"
        }
    }

    private static let bracketVowels: [Character: Letter] = [
        "[": Letter(base: "o", mod: .horn, sourceKey: "["),
        "]": Letter(base: "u", mod: .horn, sourceKey: "]"),
        "{": Letter(base: "o", mod: .horn, isUppercase: true, sourceKey: "{"),
        "}": Letter(base: "u", mod: .horn, isUppercase: true, sourceKey: "}"),
    ]
}
