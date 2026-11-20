import InputMethodKit
import os
import VietEngine

final class DirectReplaceStrategy: OutputStrategy {
    private var expectedLocation: Int?

    func isInSync(with client: any IMKTextInput) -> Bool {
        guard let expectedLocation else { return true }
        return client.selectedRange().location == expectedLocation
    }

    func apply(_ output: EngineOutput, to client: any IMKTextInput) {
        defer {
            if !output.consumed { expectedLocation = nil }
        }
        guard output.deleteCount > 0 || !output.insertText.isEmpty else { return }

        let selection = client.selectedRange()
        let caretKnown = selection.location != NSNotFound

        // Nothing to delete: insert at the app's own caret. Chat apps that just cleared their
        // field can report the old caret for a moment, and a range there would be ignored.
        guard output.deleteCount > 0 else {
            client.insertText(output.insertText, replacementRange: .notFound)
            expectedLocation = caretKnown ? selection.location + output.insertText.utf16.count : nil
            return
        }

        guard caretKnown, selection.location >= output.deleteCount else {
            Log.input.error("Caret unavailable; direct replacement degraded")
            client.insertText(output.insertText, replacementRange: .notFound)
            expectedLocation = nil
            return
        }
        let range = NSRange(location: selection.location - output.deleteCount,
                            length: output.deleteCount + selection.length)
        client.insertText(output.insertText, replacementRange: range)
        expectedLocation = range.location + output.insertText.utf16.count
    }

    func commit(_ text: String, to client: any IMKTextInput) {
        expectedLocation = nil
    }
}
