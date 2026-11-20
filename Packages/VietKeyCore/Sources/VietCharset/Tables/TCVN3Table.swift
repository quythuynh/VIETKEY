/// Uppercase toned letters have no TCVN3 code of their own and encode to the lowercase byte.
enum TCVN3Table {
    static let encode: [Character: Character] = {
        var table: [Character: Character] = [:]
        for (unicode, legacy) in zip(lowercase, lowercaseCodes) {
            table[unicode] = legacy
            if let upper = unicode.uppercased().first, upper != unicode, table[upper] == nil {
                table[upper] = legacy
            }
        }
        for (unicode, legacy) in zip(uppercase, uppercaseCodes) {
            table[unicode] = legacy
        }
        return table
    }()

    static let decode: [Character: Character] = {
        var table: [Character: Character] = [:]
        for (unicode, legacy) in zip(lowercase, lowercaseCodes) { table[legacy] = unicode }
        for (unicode, legacy) in zip(uppercase, uppercaseCodes) { table[legacy] = unicode }
        return table
    }()

    private static let lowercase = Array("àảãáạăằẳẵắặâầẩẫấậđèẻẽéẹêềểễếệìỉĩíịòỏõóọôồổỗốộơờởỡớợùủũúụưừửữứựỳỷỹýỵ")
    private static let lowercaseCodes: [Character] = [
        "\u{B5}", "\u{B6}", "\u{B7}", "\u{B8}", "\u{B9}",
        "\u{A8}", "\u{BB}", "\u{BC}", "\u{BD}", "\u{BE}", "\u{C6}",
        "\u{A9}", "\u{C7}", "\u{C8}", "\u{C9}", "\u{CA}", "\u{CB}",
        "\u{AE}",
        "\u{CC}", "\u{CE}", "\u{CF}", "\u{D0}", "\u{D1}",
        "\u{AA}", "\u{D2}", "\u{D3}", "\u{D4}", "\u{D5}", "\u{D6}",
        "\u{D7}", "\u{D8}", "\u{DC}", "\u{DD}", "\u{DE}",
        "\u{DF}", "\u{E1}", "\u{E2}", "\u{E3}", "\u{E4}",
        "\u{AB}", "\u{E5}", "\u{E6}", "\u{E7}", "\u{E8}", "\u{E9}",
        "\u{AC}", "\u{EA}", "\u{EB}", "\u{EC}", "\u{ED}", "\u{EE}",
        "\u{EF}", "\u{F1}", "\u{F2}", "\u{F3}", "\u{F4}",
        "\u{AD}", "\u{F5}", "\u{F6}", "\u{F7}", "\u{F8}", "\u{F9}",
        "\u{FA}", "\u{FB}", "\u{FC}", "\u{FD}", "\u{FE}",
    ]

    private static let uppercase = Array("ĂÂĐÊÔƠƯ")
    private static let uppercaseCodes: [Character] = ["\u{A1}", "\u{A2}", "\u{A7}", "\u{A3}", "\u{A4}", "\u{A5}", "\u{A6}"]
}
