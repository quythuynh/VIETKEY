enum VNIWindowsTable {
    static let encode: [Character: String] = {
        var table: [Character: String] = [:]
        for (vowel, sequences) in lowercaseRows {
            for (unicode, legacy) in zip(vowel, sequences) {
                table[unicode] = legacy
            }
        }
        for (vowel, sequences) in uppercaseRows {
            for (unicode, legacy) in zip(vowel, sequences) {
                table[unicode] = legacy
            }
        }
        table["đ"] = "ñ"
        table["Đ"] = "Ñ"
        return table
    }()

    static let decode: [String: Character] = {
        var table: [String: Character] = [:]
        for (unicode, legacy) in encode where legacy.count > 1 || legacy != String(unicode) {
            table[legacy] = unicode
        }
        return table
    }()

    private static let lowercaseRows: [(String, [String])] = [
        ("aáàảãạ", ["a", "aù", "aø", "aû", "aõ", "aï"]),
        ("ăắằẳẵặ", ["aê", "aé", "aè", "aú", "aü", "aë"]),
        ("âấầẩẫậ", ["aâ", "aá", "aà", "aå", "aã", "aä"]),
        ("eéèẻẽẹ", ["e", "eù", "eø", "eû", "eõ", "eï"]),
        ("êếềểễệ", ["eâ", "eá", "eà", "eå", "eã", "eä"]),
        ("iíìỉĩị", ["i", "í", "ì", "æ", "ó", "ò"]),
        ("oóòỏõọ", ["o", "où", "oø", "oû", "oõ", "oï"]),
        ("ôốồổỗộ", ["oâ", "oá", "oà", "oå", "oã", "oä"]),
        ("ơớờởỡợ", ["ô", "ôù", "ôø", "ôû", "ôõ", "ôï"]),
        ("uúùủũụ", ["u", "uù", "uø", "uû", "uõ", "uï"]),
        ("ưứừửữự", ["ö", "öù", "öø", "öû", "öõ", "öï"]),
        ("yýỳỷỹỵ", ["y", "yù", "yø", "yû", "yõ", "î"]),
    ]

    private static let uppercaseRows: [(String, [String])] = [
        ("AÁÀẢÃẠ", ["A", "AÙ", "AØ", "AÛ", "AÕ", "AÏ"]),
        ("ĂẮẰẲẴẶ", ["AÊ", "AÉ", "AÈ", "AÚ", "AÜ", "AË"]),
        ("ÂẤẦẨẪẬ", ["AÂ", "AÁ", "AÀ", "AÅ", "AÃ", "AÄ"]),
        ("EÉÈẺẼẸ", ["E", "EÙ", "EØ", "EÛ", "EÕ", "EÏ"]),
        ("ÊẾỀỂỄỆ", ["EÂ", "EÁ", "EÀ", "EÅ", "EÃ", "EÄ"]),
        ("IÍÌỈĨỊ", ["I", "Í", "Ì", "Æ", "Ó", "Ò"]),
        ("OÓÒỎÕỌ", ["O", "OÙ", "OØ", "OÛ", "OÕ", "OÏ"]),
        ("ÔỐỒỔỖỘ", ["OÂ", "OÁ", "OÀ", "OÅ", "OÃ", "OÄ"]),
        ("ƠỚỜỞỠỢ", ["Ô", "ÔÙ", "ÔØ", "ÔÛ", "ÔÕ", "ÔÏ"]),
        ("UÚÙỦŨỤ", ["U", "UÙ", "UØ", "UÛ", "UÕ", "UÏ"]),
        ("ƯỨỪỬỮỰ", ["Ö", "ÖÙ", "ÖØ", "ÖÛ", "ÖÕ", "ÖÏ"]),
        ("YÝỲỶỸỴ", ["Y", "YÙ", "YØ", "YÛ", "YÕ", "Î"]),
    ]
}
