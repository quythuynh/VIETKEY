import Testing
@testable import VietEngine

@Suite("Direct replace output")
struct OutputDiffTests {
    @Test(arguments: [
        ("", "a", 0, "a"),
        ("a", "â", 1, "â"),
        ("vie", "viê", 1, "ê"),
        ("việ", "việt", 0, "t"),
        ("abc", "", 3, ""),
    ])
    func diff(old: String, new: String, deleteCount: Int, insert: String) {
        let result = OutputDiff.between(old, new)
        #expect(result.deleteCount == deleteCount)
        #expect(result.insert == insert)
    }

    @Test(arguments: [
        "Tieengs Vieejt raast ddepj",
        "nguwowif dduwowngf ruowuj",
        "vieejt⌫⌫ef ass⌫s ww",
        "hoaf⌫ khoong ⌫⌫ x",
    ])
    func matchesMarkedTextHost(input: String) {
        #expect(TypingSimulator.typeDirect(input) == TypingSimulator.type(input))
    }
}
