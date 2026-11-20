public struct Letter: Sendable, Equatable {
    public var base: Character
    public var mod: LetterMod
    public var isUppercase: Bool
    public var sourceKey: Character?

    public init(base: Character, mod: LetterMod = .none, isUppercase: Bool = false, sourceKey: Character? = nil) {
        self.base = base
        self.mod = mod
        self.isUppercase = isUppercase
        self.sourceKey = sourceKey
    }

    init(key: Character) {
        self.init(base: Character(key.lowercased()), isUppercase: key.isUppercase)
    }

    static let vowelBases: Set<Character> = ["a", "e", "i", "o", "u", "y"]
    static let circumflexBases: Set<Character> = ["a", "e", "o"]

    var isVowel: Bool { Letter.vowelBases.contains(base) }
}
