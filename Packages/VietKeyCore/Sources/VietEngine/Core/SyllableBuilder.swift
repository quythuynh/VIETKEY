struct WordState: Equatable {
    var letters: [Letter] = []
    var tone: ToneMark = .none
    var isLiteral = false
}

/// Rebuilds the word from its raw keys on every key, which keeps free tone placement, undo and Backspace simple.
enum SyllableBuilder {
    static func build(_ keys: [Character], method: any InputMethod, literal: Bool = false) -> WordState {
        var state = WordState(isLiteral: literal)
        for key in keys {
            apply(key, to: &state, method: method)
        }
        return state
    }

    static func apply(_ key: Character, to state: inout WordState, method: any InputMethod) {
        // After an undo, or once the word is past one syllable (vietnam…), keys are plain letters.
        guard !state.isLiteral, !SpellChecker.isBeyondSyllable(state.letters) else {
            state.letters.append(Letter(key: key))
            return
        }
        for action in method.actions(for: key) {
            switch perform(action, key: key, on: &state) {
            case .applied:
                completeHorn(&state)
                return
            case .undone:
                state.isLiteral = true
                state.letters.append(Letter(key: key))
                return
            case .notApplicable:
                continue
            }
        }
        state.letters.append(Letter(key: key))
        completeHorn(&state)
    }

    /// "uơ" only ends a word (thuở); anything after it turns it into "ươ" (thương).
    private static func completeHorn(_ state: inout WordState) {
        guard let vowels = Syllable.parse(state.letters)?.vowels else { return }
        for index in vowels.dropLast() where index + 2 < state.letters.count {
            if state.letters[index].base == "u", state.letters[index].mod == .none,
               state.letters[index + 1].base == "o", state.letters[index + 1].mod == .horn {
                state.letters[index].mod = .horn
            }
        }
    }

    private enum Outcome {
        case applied, undone, notApplicable
    }

    private static func perform(_ action: KeyAction, key: Character, on state: inout WordState) -> Outcome {
        switch action {
        case .tone(let tone):
            guard Syllable.parse(state.letters) != nil else { return .notApplicable }
            if tone == .none {
                guard state.tone != .none else { return .notApplicable }
                state.tone = .none
                return .applied
            }
            if state.tone == tone {
                state.tone = .none
                return .undone
            }
            state.tone = tone
            return .applied

        case .circumflex(let base):
            guard let vowels = Syllable.parse(state.letters)?.vowels else { return .notApplicable }
            let letters = state.letters
            let matches = { (index: Int) in
                base.map { $0 == letters[index].base } ?? Letter.circumflexBases.contains(letters[index].base)
            }
            if let last = vowels.last, matches(last) {
                return applyMod(.circumflex, to: [last], in: &state)
            }
            // Typed after the word (toio → tôi), only if the result can still be Vietnamese (ngoeo ≠ ngôe).
            for index in vowels.reversed().dropFirst() where matches(index) {
                var trial = letters
                trial[index].mod = .circumflex
                if SpellChecker.isPossiblePrefix(trial) {
                    return applyMod(.circumflex, to: [index], in: &state)
                }
            }
            return .notApplicable

        case .horn:
            guard let vowels = Syllable.parse(state.letters)?.vowels else { return .notApplicable }
            return applyMod(.horn, to: hornTargets(state.letters, vowels), in: &state)

        case .breve:
            guard let vowels = Syllable.parse(state.letters)?.vowels else { return .notApplicable }
            return applyMod(.breve, to: breveTargets(state.letters, vowels), in: &state)

        case .hornOrBreve:
            guard let vowels = Syllable.parse(state.letters)?.vowels else { return .notApplicable }
            // oa takes a breve (hoặc); everything else a horn (mưa, ươ).
            if vowels.dropLast().contains(where: { state.letters[$0].base == "o" && state.letters[$0 + 1].base == "a" }) {
                return applyMod(.breve, to: breveTargets(state.letters, vowels), in: &state)
            }
            let horn = hornTargets(state.letters, vowels)
            if !horn.isEmpty { return applyMod(.horn, to: horn, in: &state) }
            return applyMod(.breve, to: breveTargets(state.letters, vowels), in: &state)

        case .stroke:
            guard state.letters.first?.base == "d" else { return .notApplicable }
            return applyMod(.stroke, to: [0], in: &state)

        case .insert(let letter, let requiresNoVowel):
            if requiresNoVowel && state.letters.contains(where: \.isVowel) { return .notApplicable }
            if let last = state.letters.last, last.sourceKey == key {
                state.letters.removeLast()
                return .undone
            }
            state.letters.append(letter)
            return .applied
        }
    }

    private static func applyMod(_ mod: LetterMod, to targets: [Int], in state: inout WordState) -> Outcome {
        guard !targets.isEmpty else { return .notApplicable }
        if targets.allSatisfy({ state.letters[$0].mod == mod }) {
            // A letter made by a key alone (w → ư) is only undone right after it (ww), not in "windows".
            let lastIndex = state.letters.count - 1
            if targets.contains(where: { state.letters[$0].sourceKey != nil && $0 != lastIndex }) {
                return .notApplicable
            }
            for index in targets.sorted(by: >) {
                if state.letters[index].sourceKey != nil {
                    state.letters.remove(at: index)
                } else {
                    state.letters[index].mod = .none
                }
            }
            return .undone
        }
        for index in targets {
            state.letters[index].mod = mod
        }
        return .applied
    }

    /// uo → ươ, or only ơ when uo ends the word (thuở).
    private static func hornTargets(_ letters: [Letter], _ vowels: Range<Int>) -> [Int] {
        if let u = vowels.dropLast().first(where: { letters[$0].base == "u" && letters[$0 + 1].base == "o" }) {
            return u + 2 == letters.count ? [u + 1] : [u, u + 1]
        }
        if let u = vowels.first(where: { letters[$0].base == "u" }) { return [u] }
        if let o = vowels.first(where: { letters[$0].base == "o" }) { return [o] }
        return []
    }

    private static func breveTargets(_ letters: [Letter], _ vowels: Range<Int>) -> [Int] {
        vowels.first(where: { letters[$0].base == "a" }).map { [$0] } ?? []
    }
}
