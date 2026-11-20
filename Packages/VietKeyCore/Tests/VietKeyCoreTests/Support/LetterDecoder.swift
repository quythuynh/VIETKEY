@testable import VietEngine

enum LetterDecoder {
    private static let toneRows: [String] = [
        "aáàảãạ", "ăắằẳẵặ", "âấầẩẫậ", "eéèẻẽẹ", "êếềểễệ", "iíìỉĩị",
        "oóòỏõọ", "ôốồổỗộ", "ơớờởỡợ", "uúùủũụ", "ưứừửữự", "yýỳỷỹỵ",
    ]
    private static let plain: [Character: (Character, LetterMod)] = [
        "a": ("a", .none), "ă": ("a", .breve), "â": ("a", .circumflex),
        "e": ("e", .none), "ê": ("e", .circumflex), "i": ("i", .none),
        "o": ("o", .none), "ô": ("o", .circumflex), "ơ": ("o", .horn),
        "u": ("u", .none), "ư": ("u", .horn), "y": ("y", .none), "đ": ("d", .stroke),
    ]

    static func decode(_ word: String) -> ([Letter], ToneMark) {
        var tone = ToneMark.none
        let letters = word.map { character -> Letter in
            var bare = character
            for row in toneRows {
                if let column = row.firstIndex(of: character) {
                    let offset = row.distance(from: row.startIndex, to: column)
                    if offset > 0 { tone = ToneMark(rawValue: offset) ?? .none }
                    bare = row.first!
                }
            }
            let (base, mod) = plain[bare] ?? (bare, .none)
            return Letter(base: base, mod: mod)
        }
        return (letters, tone)
    }
}
