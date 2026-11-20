/// Rules: Docs/TONE_RULES.md.
enum TonePlacer {
    static func position(in letters: [Letter], syllable: Syllable, style: ToneStyle) -> Int {
        let vowels = syllable.vowels
        if vowels.count == 1 { return vowels.lowerBound }

        if let marked = vowels.last(where: { letters[$0].mod != .none }) { return marked }

        if vowels.count >= 3 { return vowels.lowerBound + 1 }

        if !syllable.final.isEmpty { return vowels.lowerBound + 1 }

        let pair = String([letters[vowels.lowerBound].base, letters[vowels.lowerBound + 1].base])
        if style == .new && (pair == "oa" || pair == "oe" || pair == "uy") {
            return vowels.lowerBound + 1
        }
        return vowels.lowerBound
    }
}
