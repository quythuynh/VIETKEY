import Testing
@testable import VietEngine

@Suite("Telex")
struct TelexTests {
    @Test(arguments: [
        ("vieejt", "việt"),
        ("nguwowif", "người"),
        ("ddaay", "đây"),
        ("tieengs", "tiếng"),
        ("khoong", "không"),
        ("dduwowngf", "đường"),
        ("hoawcj", "hoặc"),
        ("muwa", "mưa"),
        ("muaw", "mưa"),
        ("cuwus", "cứu"),
        ("ruowuj", "rượu"),
        ("nguyeenx", "nguyễn"),
        ("quaf", "quà"),
        ("gias", "giá"),
        ("gif", "gì"),
        ("gieengs", "giếng"),
        ("tooi", "tôi"),
        ("ddi", "đi"),
        ("toans", "toán"),
        ("hoangf", "hoàng"),
        ("khoais", "khoái"),
        ("ngoeoj", "ngoẹo"),
        ("thuowr", "thuở"),
        ("huow", "huơ"),
        ("thuowng", "thương"),
        ("thuwowng", "thương"),
        ("truowcs", "trước"),
        ("quowr", "quở"),
        ("thuees", "thuế"),
        ("tuaan", "tuân"),
        ("quawngs", "quắng"),
        ("ow", "ơ"),
        ("ơi", "ơi"),
    ])
    func words(input: String, expected: String) {
        #expect(TypingSimulator.type(input) == expected)
    }

    @Test(arguments: [
        ("w", "ư"),
        ("tw", "tư"),
        ("ww", "w"),
        ("aa", "â"),
        ("aaa", "aa"),
        ("aw", "ă"),
        ("aww", "aw"),
        ("dd", "đ"),
        ("ddd", "dd"),
        ("as", "á"),
        ("ass", "as"),
        ("asz", "a"),
        ("z", "z"),
        ("s", "s"),
        ("asf", "à"),
    ])
    func modifiersAndUndo(input: String, expected: String) {
        #expect(TypingSimulator.type(input, options: TypingSimulator.mechanics) == expected)
    }

    @Test(arguments: [
        ("vieetj", "việt"),
        ("tana", "tân"),
        ("did", "đi"),
        ("thuowngf", "thường"),
        ("nguoiwf", "người"),
        ("tienef", "tiền"),
        ("tienfe", "tiền"),
        ("toio", "tôi"),
        ("tuyenre", "tuyển"),
        ("ngoeoj", "ngoẹo"),
    ])
    func freeMarking(input: String, expected: String) {
        #expect(TypingSimulator.type(input) == expected)
    }

    @Test(arguments: [
        ("Vieejt", "Việt"),
        ("VIEEJT", "VIỆT"),
        ("DDaay", "Đây"),
        ("Ddaay", "Đây"),
        ("W", "Ư"),
        ("NGUWOWIF", "NGƯỜI"),
    ])
    func uppercase(input: String, expected: String) {
        #expect(TypingSimulator.type(input) == expected)
    }

    @Test func sentence() {
        #expect(TypingSimulator.type("Tieengs Vieejt raast ddepj, 2026!") == "Tiếng Việt rất đẹp, 2026!")
    }

    @Test(arguments: [
        ("o[", "oơ"),
        ("[", "ơ"),
        ("t]", "tư"),
        ("}", "Ư"),
    ])
    func extended(input: String, expected: String) {
        let options = EngineOptions(inputMethod: .telexExtended, spellCheck: false)
        #expect(TypingSimulator.type(input, options: options) == expected)
    }

    @Test func bracketsEndWordsInBasicTelex() {
        #expect(TypingSimulator.type("as[") == "á[")
    }

    @Test func reapplyingSameOptionsKeepsWord() {
        var engine = VietEngine()
        for key in "tien" { _ = engine.process(.character(key)) }
        engine.options = EngineOptions()
        _ = engine.process(.character("e"))
        _ = engine.process(.character("f"))
        #expect(engine.composing == "tiền")
    }
}
