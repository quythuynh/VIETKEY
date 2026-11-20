struct Syllable: Equatable {
    let initial: Range<Int>
    let vowels: Range<Int>
    let final: Range<Int>

    static func parse(_ letters: [Letter]) -> Syllable? {
        guard var start = letters.firstIndex(where: \.isVowel) else { return nil }

        // qu / gi: the u / i belongs to the initial when another vowel follows (quà, giữa).
        if start == 1, letters.count > 2, letters[2].isVowel, letters[1].mod == .none {
            let first = letters[0].base, second = letters[1].base
            if (first == "q" && second == "u") || (first == "g" && second == "i") {
                start = 2
            }
        }

        var end = start
        while end < letters.count, letters[end].isVowel {
            end += 1
        }
        return Syllable(initial: 0..<start, vowels: start..<end, final: end..<letters.count)
    }
}
