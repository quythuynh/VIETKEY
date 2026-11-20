import AppKit
import VietEngine

final class QuickInputTextView: NSTextView {
    var onSend: (() -> Void)?
    var onCancel: (() -> Void)?

    private var engine = VietEngine()
    private var expectedLocation: Int?

    /// Keys bypass the input method system: VietKey is both the input method and the owner of this view.
    override var inputContext: NSTextInputContext? { nil }

    func prepare(options: EngineOptions) {
        engine.options = options
        engine.reset()
        string = ""
        expectedLocation = nil
    }

    func finishedText() -> String {
        commitWord()
        return string
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
        switch event.keyCode {
        case KeyCode.returnKey, KeyCode.keypadEnter:
            commitWord()
            if flags == .shift {
                insertText("\n", replacementRange: .notFound)
            } else {
                onSend?()
            }
            return
        case KeyCode.escape:
            onCancel?()
            return
        default:
            break
        }

        switch KeyEventMapper.map(event) {
        case .commitAndPass:
            commitWord()
            super.keyDown(with: event)
        case .engine(let key):
            if engine.isComposing && selectedRange().location != expectedLocation {
                engine.reset()
            }
            let output = engine.process(key)
            apply(deleteCount: output.deleteCount, insert: output.insertText)
            guard !output.consumed else { return }
            expectedLocation = nil
            switch key {
            case .backspace: deleteBackward(nil)
            case .character(let character): insertText(String(character), replacementRange: .notFound)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        commitWord()
        super.mouseDown(with: event)
    }

    private func commitWord() {
        guard engine.isComposing else { return }
        let shown = engine.composing
        let text = engine.commit()
        let diff = OutputDiff.between(shown, text)
        apply(deleteCount: diff.deleteCount, insert: diff.insert)
        expectedLocation = nil
    }

    private func apply(deleteCount: Int, insert: String) {
        guard deleteCount > 0 || !insert.isEmpty else { return }
        let selection = selectedRange()
        let range = NSRange(location: max(0, selection.location - deleteCount),
                            length: min(deleteCount, selection.location) + selection.length)
        insertText(insert, replacementRange: range)
        expectedLocation = selectedRange().location
    }
}
