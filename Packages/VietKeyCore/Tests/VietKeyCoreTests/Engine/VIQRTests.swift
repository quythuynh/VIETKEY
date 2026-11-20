import Testing
@testable import VietEngine

@Suite("VIQR")
struct VIQRTests {
    private let options = EngineOptions(inputMethod: .viqr)

    @Test(arguments: [
        ("Vie^.t", "Việt"),
        ("ngu+o+`i", "người"),
        ("ddu+o+`ng", "đường"),
        ("a(n", "ăn"),
        ("a.", "ạ"),
        ("thuo+?", "thuở"),
    ])
    func words(input: String, expected: String) {
        #expect(TypingSimulator.type(input, options: options) == expected)
    }

    @Test func doubledMarkIsLiteral() {
        let options = EngineOptions(inputMethod: .viqr, spellCheck: false)
        #expect(TypingSimulator.type("a..", options: options) == "a.")
    }

    @Test func punctuationOutsideWordsPassesThrough() {
        #expect(TypingSimulator.type("? (x)", options: options) == "? (x)")
    }

    @Test func apostropheInEnglishIsRestored() {
        #expect(TypingSimulator.type("don't", options: options) == "don't")
    }
}
