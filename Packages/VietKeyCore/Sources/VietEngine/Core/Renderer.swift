enum Renderer {
    static func render(_ letters: [Letter], tone: ToneMark, style: ToneStyle) -> String {
        var tonePosition = -1
        if tone != .none, let syllable = Syllable.parse(letters) {
            tonePosition = TonePlacer.position(in: letters, syllable: syllable, style: style)
        }

        var output = ""
        for (index, letter) in letters.enumerated() {
            let character = character(for: letter, tone: index == tonePosition ? tone : .none)
            if letter.isUppercase {
                output += character.uppercased()
            } else {
                output.append(character)
            }
        }
        return output
    }

    static func spelling(_ letters: ArraySlice<Letter>) -> String {
        String(letters.map { character(for: $0, tone: .none) })
    }

    private static func character(for letter: Letter, tone: ToneMark) -> Character {
        if let row = toneRow(base: letter.base, mod: letter.mod) {
            return row[tone.rawValue]
        }
        if letter.base == "d" && letter.mod == .stroke { return "đ" }
        return letter.base
    }

    /// Columns follow ToneMark order: none, sắc, huyền, hỏi, ngã, nặng.
    private static func toneRow(base: Character, mod: LetterMod) -> [Character]? {
        switch (base, mod) {
        case ("a", .none): rowA
        case ("a", .breve): rowĂ
        case ("a", .circumflex): rowÂ
        case ("e", .none): rowE
        case ("e", .circumflex): rowÊ
        case ("i", .none): rowI
        case ("o", .none): rowO
        case ("o", .circumflex): rowÔ
        case ("o", .horn): rowƠ
        case ("u", .none): rowU
        case ("u", .horn): rowƯ
        case ("y", .none): rowY
        default: nil
        }
    }

    private static let rowA: [Character] = Array("aáàảãạ")
    private static let rowĂ: [Character] = Array("ăắằẳẵặ")
    private static let rowÂ: [Character] = Array("âấầẩẫậ")
    private static let rowE: [Character] = Array("eéèẻẽẹ")
    private static let rowÊ: [Character] = Array("êếềểễệ")
    private static let rowI: [Character] = Array("iíìỉĩị")
    private static let rowO: [Character] = Array("oóòỏõọ")
    private static let rowÔ: [Character] = Array("ôốồổỗộ")
    private static let rowƠ: [Character] = Array("ơớờởỡợ")
    private static let rowU: [Character] = Array("uúùủũụ")
    private static let rowƯ: [Character] = Array("ưứừửữự")
    private static let rowY: [Character] = Array("yýỳỷỹỵ")
}
