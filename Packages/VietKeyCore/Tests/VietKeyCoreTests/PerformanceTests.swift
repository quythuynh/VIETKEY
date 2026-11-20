import Testing
@testable import VietEngine

@Suite("Performance")
struct PerformanceTests {
    @Test func underOneMillisecondPerKey() {
        let text = String(repeating: "nguwowif dduwowngf vieejt khoong tieengs ", count: 500)
        let clock = ContinuousClock()
        var engine = VietEngine()
        let elapsed = clock.measure {
            for character in text {
                _ = engine.process(.character(character))
            }
        }
        let perKey = elapsed / text.count
        #expect(perKey < .milliseconds(1), "per key: \(perKey)")
    }
}
