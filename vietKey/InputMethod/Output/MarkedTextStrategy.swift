import InputMethodKit
import VietEngine

final class MarkedTextStrategy: OutputStrategy {
    private var hasMarkedText = false

    func isInSync(with client: any IMKTextInput) -> Bool {
        true
    }

    func apply(_ output: EngineOutput, to client: any IMKTextInput) {
        if !output.commitText.isEmpty {
            insert(output.commitText, into: client)
        }
        if output.consumed {
            setMarkedText(output.composing, in: client)
        }
    }

    func commit(_ text: String, to client: any IMKTextInput) {
        if !text.isEmpty {
            insert(text, into: client)
        } else if hasMarkedText {
            setMarkedText("", in: client)
        }
    }

    private func insert(_ text: String, into client: any IMKTextInput) {
        client.insertText(text, replacementRange: .notFound)
        hasMarkedText = false
    }

    private func setMarkedText(_ text: String, in client: any IMKTextInput) {
        let caret = NSRange(location: text.utf16.count, length: 0)
        client.setMarkedText(text, selectionRange: caret, replacementRange: .notFound)
        hasMarkedText = !text.isEmpty
    }
}
