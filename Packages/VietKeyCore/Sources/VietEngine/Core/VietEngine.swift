public struct VietEngine: Sendable {
    public var options: EngineOptions {
        didSet {
            // Hosts re-apply settings on focus changes; only a real change may end the word.
            guard options != oldValue else { return }
            method = options.inputMethod.method
            reset()
        }
    }

    public private(set) var composing = ""

    private var method: any InputMethod
    private var rawKeys: [Character] = []
    private var state = WordState()
    private var startsLiteral = false
    private var showsTypedKeys = false

    public init(options: EngineOptions = EngineOptions()) {
        self.options = options
        self.method = options.inputMethod.method
    }

    public var isComposing: Bool { !rawKeys.isEmpty }

    public mutating func process(_ key: KeyInput) -> EngineOutput {
        switch key {
        case .character(let character):
            let continuesWord = isComposing ? method.isWordKey(character) : method.canStartWord(character)
            guard continuesWord else {
                let shown = composing
                let text = commit()
                let diff = OutputDiff.between(shown, text)
                return EngineOutput(consumed: false, commitText: text, deleteCount: diff.deleteCount, insertText: diff.insert)
            }
            rawKeys.append(character)
            state = SyllableBuilder.build(rawKeys, method: method, literal: startsLiteral)
            return render()

        case .backspace:
            guard !state.letters.isEmpty else { return .passThrough }
            if showsTypedKeys {
                rawKeys.removeLast()
                state = rawKeys.isEmpty ? WordState() : SyllableBuilder.build(rawKeys, method: method, literal: startsLiteral)
            } else {
                deleteLastLetter()
            }
            return render()
        }
    }

    public mutating func commit() -> String {
        let text = finalText()
        reset()
        return text
    }

    /// Ends the word exactly as displayed, without macros or restoring keys: for focus changes,
    /// clicks and shortcuts, which aren't the user finishing the word.
    public mutating func commitAsShown() -> String {
        let text = composing
        reset()
        return text
    }

    private func finalText() -> String {
        guard isComposing else { return "" }
        let typed = String(rawKeys)
        if let expansion = options.macros.expansion(for: composing) ?? options.macros.expansion(for: typed) {
            return expansion
        }
        // Words without a vowel (đ) and words made literal by an undo stay as typed.
        if options.spellCheck, composing != typed, !state.isLiteral,
           state.letters.contains(where: \.isVowel),
           !SpellChecker.isValid(state.letters, tone: state.tone) {
            return typed
        }
        return composing
    }

    public mutating func reset() {
        rawKeys.removeAll()
        state = WordState()
        startsLiteral = false
        showsTypedKeys = false
        composing = ""
    }

    /// Backspace removes the last displayed letter (việt → việ), not the last key.
    private mutating func deleteLastLetter() {
        var expected = state
        if state.tone != .none, let syllable = Syllable.parse(state.letters),
           TonePlacer.position(in: state.letters, syllable: syllable, style: options.toneStyle) == state.letters.count - 1 {
            expected.tone = .none
        }
        expected.letters.removeLast()
        if !expected.letters.contains(where: \.isVowel) {
            expected.tone = .none
        }
        guard !expected.letters.isEmpty else {
            rawKeys.removeAll()
            state = WordState()
            startsLiteral = false
            return
        }

        if !expected.isLiteral {
            var keys = expected.letters.flatMap { method.keys(for: $0) }
            if let toneKey = method.key(for: expected.tone) {
                keys.append(toneKey)
            }
            if SyllableBuilder.build(keys, method: method) == expected {
                rawKeys = keys
                startsLiteral = false
                state = expected
                return
            }
        }

        rawKeys = Array(Renderer.render(expected.letters, tone: expected.tone, style: options.toneStyle))
        startsLiteral = true
        state = SyllableBuilder.build(rawKeys, method: method, literal: true)
    }

    private mutating func render() -> EngineOutput {
        var text = Renderer.render(state.letters, tone: state.tone, style: options.toneStyle)
        let typed = String(rawKeys)
        // Show the raw keys while no further key could make the word Vietnamese (ỉnte, câl).
        showsTypedKeys = options.spellCheck && !state.isLiteral && text != typed
            && !SpellChecker.isPossiblePrefix(state.letters, tone: state.tone)
        if showsTypedKeys {
            text = typed
        }
        let diff = OutputDiff.between(composing, text)
        composing = text
        return EngineOutput(consumed: true, composing: text, deleteCount: diff.deleteCount, insertText: diff.insert)
    }
}
