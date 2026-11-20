import Testing
@testable import VietEngine

@Suite("Tone placement")
struct TonePlacerTests {
    @Test(arguments: [
        ("hoaf", "hoà", "hòa"),
        ("khoer", "khoẻ", "khỏe"),
        ("thuyr", "thuỷ", "thủy"),
        ("hoas", "hoá", "hóa"),
        ("hoanf", "hoàn", "hoàn"),
        ("muas", "múa", "múa"),
        ("kiaf", "kìa", "kìa"),
        ("tais", "tái", "tái"),
        ("caus", "cáu", "cáu"),
        ("quys", "quý", "quý"),
    ])
    func styles(input: String, new: String, old: String) {
        #expect(TypingSimulator.type(input, options: EngineOptions(toneStyle: .new)) == new)
        #expect(TypingSimulator.type(input, options: EngineOptions(toneStyle: .old)) == old)
    }

    @Test func toneMovesWhenVowelsGrow() {
        #expect(TypingSimulator.type("gifa") == "già")
        #expect(TypingSimulator.type("hofa") == "hoà")
        #expect(TypingSimulator.type("hofan") == "hoàn")
    }
}
