public enum KeyAction: Sendable, Equatable {
    case tone(ToneMark)
    case circumflex(Character?)
    case horn
    case breve
    case hornOrBreve
    case stroke
    case insert(Letter, requiresNoVowel: Bool)
}

public protocol InputMethod: Sendable {
    func isWordKey(_ key: Character) -> Bool
    func canStartWord(_ key: Character) -> Bool
    func actions(for key: Character) -> [KeyAction]
    func keys(for letter: Letter) -> [Character]
    func key(for tone: ToneMark) -> Character?
}

extension InputMethod {
    public func canStartWord(_ key: Character) -> Bool {
        key.isASCII && key.isLetter
    }
}
