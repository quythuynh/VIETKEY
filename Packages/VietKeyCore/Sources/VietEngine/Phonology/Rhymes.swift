enum Rhymes {
    static let valid: Set<String> = [
        "a", "ac", "ach", "ai", "am", "an", "ang", "anh", "ao", "ap", "at", "au", "ay",
        "ăc", "ăm", "ăn", "ăng", "ăp", "ăt",
        "âc", "âm", "ân", "âng", "âp", "ât", "âu", "ây",
        "e", "ec", "em", "en", "eng", "eo", "ep", "et",
        "ê", "êch", "êm", "ên", "êng", "ênh", "êp", "êt", "êu",
        "i", "ia", "ich", "im", "in", "inh", "ip", "it", "iu",
        "iêc", "iêm", "iên", "iêng", "iêp", "iêt", "iêu",
        "o", "oc", "oi", "om", "on", "ong", "op", "ot", "ooc", "oong",
        "oa", "oac", "oach", "oai", "oam", "oan", "oang", "oanh", "oao", "oap", "oat", "oay",
        "oăc", "oăm", "oăn", "oăng", "oăt",
        "oe", "oem", "oen", "oeo", "oet",
        "ô", "ôc", "ôi", "ôm", "ôn", "ông", "ôp", "ôt",
        "ơ", "ơi", "ơm", "ơn", "ơp", "ơt",
        "u", "ua", "uc", "ui", "um", "un", "ung", "up", "ut",
        "uân", "uâng", "uât", "uây",
        "uê", "uêch", "uênh",
        "uôc", "uôi", "uôm", "uôn", "uông", "uôt",
        "uơ",
        "uy", "uya", "uych", "uyn", "uynh", "uyp", "uyt", "uyu",
        "uyên", "uyêt",
        "ư", "ưa", "ưc", "ưi", "ưm", "ưn", "ưng", "ưt", "ưu",
        "ươc", "ươi", "ươm", "ươn", "ương", "ươp", "ươt", "ươu",
        "y", "ych", "ynh", "yt",
        "yêm", "yên", "yêt", "yêu",
    ]

    static let finalPrefixes: Set<String> = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t"]

    static let prefixes: Set<String> = {
        var result: Set<String> = []
        for rhyme in valid {
            var prefix = ""
            for character in rhyme {
                prefix.append(character)
                result.insert(prefix)
            }
        }
        return result
    }()

    static let stopTones: Set<ToneMark> = [.none, .acute, .dot]

    static func endsWithStop(_ rhyme: String) -> Bool {
        rhyme.hasSuffix("c") || rhyme.hasSuffix("ch") || rhyme.hasSuffix("p") || rhyme.hasSuffix("t")
    }
}
