enum Initials {
    static let valid: Set<String> = [
        "", "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh", "l", "m", "n",
        "ng", "ngh", "nh", "p", "ph", "qu", "r", "s", "t", "th", "tr", "v", "x",
    ]

    static let prefixes: Set<String> = {
        var result: Set<String> = [""]
        for initial in valid {
            var prefix = ""
            for character in initial {
                prefix.append(character)
                result.insert(prefix)
            }
        }
        return result
    }()

    static let frontVowelOnly: Set<String> = ["k", "gh", "ngh"]

    static let frontVowels: Set<Character> = ["i", "e", "ê"]

    static let backVowelOnly: Set<String> = ["c", "ng"]
}
