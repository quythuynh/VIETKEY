enum SpellChecker {
    static func isBeyondSyllable(_ letters: [Letter]) -> Bool {
        guard let syllable = Syllable.parse(letters) else { return false }
        let final = letters[syllable.final]
        if final.contains(where: \.isVowel) { return true }
        return !Rhymes.finalPrefixes.contains(Renderer.spelling(final))
    }

    /// Whether more keys could still make a valid syllable ("tuô" → tuôn, "ngh" → nghe).
    static func isPossiblePrefix(_ letters: [Letter], tone: ToneMark = .none) -> Bool {
        guard let parts = SpelledSyllable(letters) else {
            return Initials.prefixes.contains(Renderer.spelling(letters[...]))
        }
        return Rhymes.prefixes.contains(parts.rhyme) && parts.followsInitialAndToneRules(tone: tone)
    }

    static func isValid(_ letters: [Letter], tone: ToneMark) -> Bool {
        guard let parts = SpelledSyllable(letters) else { return false }
        return Rhymes.valid.contains(parts.rhyme) && parts.followsInitialAndToneRules(tone: tone)
    }
}

/// A single syllable spelled out as initial + rhyme, without tone.
private struct SpelledSyllable {
    let initial: String
    let rhyme: String

    init?(_ letters: [Letter]) {
        guard let syllable = Syllable.parse(letters), !letters[syllable.final].contains(where: \.isVowel) else {
            return nil
        }
        initial = Renderer.spelling(letters[syllable.initial])
        rhyme = Renderer.spelling(letters[syllable.vowels.lowerBound...])
    }

    func followsInitialAndToneRules(tone: ToneMark) -> Bool {
        guard Initials.valid.contains(initial), let first = rhyme.first else { return false }
        let frontVowel = Initials.frontVowels.contains(first)
        if Initials.frontVowelOnly.contains(initial) && !(frontVowel || first == "y") { return false }
        if Initials.backVowelOnly.contains(initial) && frontVowel { return false }
        // c, ch, p, t stay stops whatever follows, so a wrong tone can't be fixed later (tẽt).
        return !Rhymes.endsWithStop(rhyme) || Rhymes.stopTones.contains(tone)
    }
}
