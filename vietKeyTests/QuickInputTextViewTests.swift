import AppKit
import Testing
@testable import vietKey
import VietEngine

@Suite("Quick input box")
struct QuickInputTextViewTests {
    func type(_ input: String) -> (text: String, sent: String?) {
        let view = QuickInputTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))
        var sent: String?
        view.onSend = { sent = view.string }
        view.prepare(options: EngineOptions())
        for character in input {
            view.keyDown(with: KeyEvents.key(character))
        }
        return (view.finishedText(), sent)
    }

    @Test(arguments: [
        ("Tieengs Vieejt raast ddepj", "Tiếng Việt rất đẹp"),
        ("vietnamese text internet", "vietnamese text internet"),
        ("nguoif⌫w cala ", "ngươi cala "),
    ])
    func composesVietnamese(input: String, expected: String) {
        #expect(type(input).text == expected)
    }

    @Test func returnSendsTheText() {
        #expect(type("xin chaof⏎").sent == "xin chào")
    }
}
