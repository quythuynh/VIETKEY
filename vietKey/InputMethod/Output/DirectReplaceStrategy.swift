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
        if output.deleteCount > 0 || !output.insertText.isEmpty {
            let selection = client.selectedRange()
            if selection.location != NSNotFound, selection.location >= output.deleteCount {
                let range = NSRange(location: selection.location - output.deleteCount,
                                    length: output.deleteCount + selection.length)
                client.insertText(output.insertText, replacementRange: range)
                expectedLocation = range.location + output.insertText.utf16.count
            } else {
                Log.input.error("selectedRange unavailable; direct replacement degraded")
                client.insertText(output.insertText, replacementRange: .notFound)
                expectedLocation = nil
            }
        }
        if !output.consumed {
            expectedLocation = nil
        }
    }

    func commit(_ text: String, to client: any IMKTextInput) {
        expectedLocation = nil
    }
}
