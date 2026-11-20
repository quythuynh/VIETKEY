import Testing
@testable import VietEngine

@Suite("VNI")
struct VNITests {
    private let options = EngineOptions(inputMethod: .vni)

    @Test(arguments: [
        ("Vie65t", "Việt"),
        ("vie6t5", "việt"),
        ("nguo72i", "người"),
        ("d9uo7ng2", "đường"),
        ("thuo73", "thuở"),
        ("hoa82c5", "hoặc"),
        ("mu7a", "mưa"),
        ("hoa2", "hoà"),
        ("a1", "á"),
        ("A6n", "Ân"),
    ])
    func words(input: String, expected: String) {
        #expect(TypingSimulator.type(input, options: options) == expected)
    }

    @Test(arguments: [
        ("a66", "a6"),
        ("a11", "a1"),
        ("d99", "d9"),
        ("a10", "a"),
    ])
    func undo(input: String, expected: String) {
        let options = EngineOptions(inputMethod: .vni, spellCheck: false)
        #expect(TypingSimulator.type(input, options: options) == expected)
    }

    @Test func numbersPassThrough() {
        #expect(TypingSimulator.type("Na8m 2026 co1 12 tha1ng", options: options) == "Năm 2026 có 12 tháng")
    }

    @Test func backspaceRebuildsWithVNIKeys() {
        let options = EngineOptions(inputMethod: .vni, spellCheck: false)
        #expect(TypingSimulator.type("d9uo7ng2⌫⌫", options: options) == "đườ")
    }
}
