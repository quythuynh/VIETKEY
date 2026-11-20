import Testing
@testable import VietEngine

@Suite("Macros")
struct MacroTests {
    private let options = EngineOptions(macros: MacroTable(["vn": "Việt Nam", "ko": "không", "hn": "Hà Nội"]))

    @Test func expandsWhenWordEnds() {
        #expect(TypingSimulator.type("toi o vn.", options: options) == "toi o Việt Nam.")
    }

    @Test func matchesCase() {
        #expect(TypingSimulator.type("Ko KO ko", options: options) == "Không KHÔNG không")
    }

    @Test func directReplaceMatchesMarkedText() {
        let input = "hn ko vn, Vieejt"
        #expect(TypingSimulator.typeDirect(input, options: options) == TypingSimulator.type(input, options: options))
    }

    @Test func fileFormatRoundTrip() {
        let file = """
        ;DO NOT DELETE THIS LINE*** version=1 ***
        vn:Việt Nam
        ko : không
        ; comment
        broken line
        url:https://example.com
        """
        let entries = MacroFileFormat.parse(file)
        #expect(entries == ["vn": "Việt Nam", "ko": "không", "url": "https://example.com"])
        #expect(MacroFileFormat.parse(MacroFileFormat.serialize(entries)) == entries)
    }
}
