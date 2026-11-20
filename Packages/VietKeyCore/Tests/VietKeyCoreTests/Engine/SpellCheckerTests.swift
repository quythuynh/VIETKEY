import Testing
@testable import VietEngine

@Suite("Spell check and restore")
struct SpellCheckerTests {
    @Test(arguments: [
        ("text", "text"),
        ("word", "word"),
        ("windows", "windows"),
        ("tesst", "test"),
        ("Vieejt", "Việt"),
        ("nguwowif", "người"),
        ("dd", "đ"),
        ("w", "ư"),
        ("ass", "as"),
        ("vietnamese", "vietnamese"),
        ("vietnamesse", "vietnamesse"),
        ("internet", "internet"),
        ("vietnamsese", "vietnamsese"),
    ])
    func restoresInvalidWords(input: String, expected: String) {
        #expect(TypingSimulator.type(input) == expected)
    }

    @Test func restoreKeepsCase() {
        #expect(TypingSimulator.type("TEXT Text") == "TEXT Text")
    }

    @Test func disabledKeepsTransformation() {
        #expect(TypingSimulator.type("text", options: TypingSimulator.mechanics) == "tẽt")
    }

    @Test func validVietnameseIsNotRestored() {
        #expect(TypingSimulator.type("this") == "thí")
    }

    @Test(arguments: ["việt", "người", "khuỷu", "quyển", "giếng", "nghiêng", "kìa", "boong", "thuở", "ạ"])
    func validWords(word: String) {
        #expect(isValid(word), "\(word)")
    }

    @Test(arguments: ["tẽt", "kan", "ngi", "ce", "ưo", "â", "tana", "nghâ", "bk"])
    func invalidWords(word: String) {
        #expect(!isValid(word), "\(word)")
    }

    private func isValid(_ word: String) -> Bool {
        let (letters, tone) = LetterDecoder.decode(word)
        return SpellChecker.isValid(letters, tone: tone)
    }

    @Test(arguments: [
        ("inter", "i in int inte inter"),
        ("cala", "c ca cal cala"),
        ("text", "t te tẽ text"),
        ("google", "g go gô goog googl google"),
        ("nguoifw", "n ng ngu nguo nguoi nguoif người"),
        ("ddaay", "d đ đa đâ đây"),
        ("tienef", "t ti tie tien tiên tiền"),
        ("vietnamese", "v vi vie viet vietn vietna vietnam vietname vietnames vietnamese"),
        ("vietnamesse", "v vi vie viet vietn vietna vietnam vietname vietnames vietnamess vietnamesse"),
        ("canaf", "c ca can cân cần"),
    ])
    func liveSpellCheck(input: String, expected: String) {
        var engine = VietEngine()
        let steps = input.map { engine.process(.character($0)).composing }
        #expect(steps.joined(separator: " ") == expected)
    }

    @Test(arguments: [
        ("cala⌫", "cal"),
        ("cala⌫a", "cala"),
        ("inter⌫⌫⌫", "in"),
        ("text⌫", "tẽ"),
        ("nguoif⌫w", "ngươi"),
    ])
    func backspaceOnTypedKeys(input: String, expected: String) {
        #expect(TypingSimulator.type(input) == expected)
    }

    @Test func liveSpellCheckMatchesDirectReplace() {
        let input = "inter internet cala text nguoifw google ⌫⌫ tienef"
        #expect(TypingSimulator.typeDirect(input) == TypingSimulator.type(input))
    }
}
