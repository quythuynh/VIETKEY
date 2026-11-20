struct VIQR: InputMethod {
    private static let markKeys: Set<Character> = ["'", "`", "?", "~", ".", "-", "^", "(", "+"]

    func isWordKey(_ key: Character) -> Bool {
        (key.isASCII && key.isLetter) || VIQR.markKeys.contains(key)
    }

    func actions(for key: Character) -> [KeyAction] {
        switch key {
        case "'": [.tone(.acute)]
        case "`": [.tone(.grave)]
        case "?": [.tone(.hook)]
        case "~": [.tone(.tilde)]
        case ".": [.tone(.dot)]
        case "-": [.tone(.none)]
        case "^": [.circumflex(nil)]
        case "(": [.breve]
        case "+": [.horn]
        case "d", "D": [.stroke]
        default: []
        }
    }

    func keys(for letter: Letter) -> [Character] {
        let base = letter.isUppercase ? Character(letter.base.uppercased()) : letter.base
        switch letter.mod {
        case .none: return [base]
        case .circumflex: return [base, "^"]
        case .breve: return [base, "("]
        case .horn: return [base, "+"]
        case .stroke: return [base, "d"]
        }
    }

    func key(for tone: ToneMark) -> Character? {
        switch tone {
        case .none: nil
        case .acute: "'"
        case .grave: "`"
        case .hook: "?"
        case .tilde: "~"
        case .dot: "."
        }
    }
}
