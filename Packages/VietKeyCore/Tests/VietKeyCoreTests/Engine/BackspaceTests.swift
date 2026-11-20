import Testing
@testable import VietEngine

@Suite("Backspace")
struct BackspaceTests {
    @Test(arguments: [
        ("vieejt⌫", "việ"),
        ("vieetj⌫", "việ"),
        ("nguwowif⌫", "ngườ"),
        ("nguwowif⌫⌫", "ngư"),
        ("dduwowngf⌫⌫", "đườ"),
        ("as⌫", ""),
        ("as⌫b", "b"),
        ("ab⌫⌫⌫", ""),
        ("x ⌫⌫", ""),
        ("ass⌫", "a"),
        ("ass⌫s", "as"),
        ("w⌫", ""),
        ("hoaf⌫", "ho"),
        ("vieejt⌫t", "việt"),
        ("vieejt⌫⌫", "vi"),
        ("vieejt⌫⌫eej", "việ"),
        ("thuowngf⌫⌫", "thườ"),
        ("thuowngf⌫⌫⌫", "thư"),
    ])
    func deletesLastDisplayedLetter(input: String, expected: String) {
        #expect(TypingSimulator.type(input, options: TypingSimulator.mechanics) == expected)
    }

    @Test func backspaceWithNothingComposingPassesThrough() {
        var engine = VietEngine()
        #expect(engine.process(.backspace) == .passThrough)
    }
}
