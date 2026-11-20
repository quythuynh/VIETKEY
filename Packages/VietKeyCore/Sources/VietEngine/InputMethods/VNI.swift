struct VNI: InputMethod {
    func isWordKey(_ key: Character) -> Bool {
        key.isASCII && (key.isLetter || key.isNumber)
    }

    func actions(for key: Character) -> [KeyAction] {
        switch key {
        case "1": [.tone(.acute)]
        case "2": [.tone(.grave)]
        case "3": [.tone(.hook)]
        case "4": [.tone(.tilde)]
        case "5": [.tone(.dot)]
        case "0": [.tone(.none)]
        case "6": [.circumflex(nil)]
        case "7": [.horn]
        case "8": [.breve]
        case "9": [.stroke]
        default: []
        }
    }

    func keys(for letter: Letter) -> [Character] {
        let base = letter.isUppercase ? Character(letter.base.uppercased()) : letter.base
        switch letter.mod {
        case .none: return [base]
        case .circumflex: return [base, "6"]
        case .horn: return [base, "7"]
        case .breve: return [base, "8"]
        case .stroke: return [base, "9"]
        }
    }

    func key(for tone: ToneMark) -> Character? {
        switch tone {
        case .none: nil
        case .acute: "1"
        case .grave: "2"
        case .hook: "3"
        case .tilde: "4"
        case .dot: "5"
        }
    }
}
