import InputMethodKit
import os
import VietEngine

final class DirectReplaceStrategy: OutputStrategy {
    /// Where the current word ends on screen, and the word as written there.
    private var expectedLocation: Int?
    private var shownWord = ""

    /// The word is still being typed if the caret sits right after what we wrote. When the caret
    /// isn't where we expected (the location we computed from a stale caret, e.g. right after a
    /// chat app cleared its field), the text before it decides.
    func isInSync(with client: any IMKTextInput) -> Bool {
        guard !shownWord.isEmpty else { return true }
        let caret = client.selectedRange().location
        guard caret != NSNotFound else { return false }
        if caret == expectedLocation { return true }
        guard wordEnds(at: caret, in: client) == true else { return false }
        expectedLocation = caret
        return true
    }

    func apply(_ output: EngineOutput, to client: any IMKTextInput) {
        defer {
            shownWord = output.consumed ? output.composing : ""
            if !output.consumed { expectedLocation = nil }
        }
        guard output.deleteCount > 0 || !output.insertText.isEmpty else { return }

        // Starting a word: insert at the app's own caret, a reported one may be stale.
        guard output.deleteCount > 0 else {
            let caret = client.selectedRange().location
            client.insertText(output.insertText, replacementRange: .notFound)
            expectedLocation = caret == NSNotFound ? nil : caret + output.insertText.utf16.count
            return
        }

        guard let end = expectedLocation ?? knownCaret(of: client), end >= output.deleteCount else {
            Log.input.error("Caret unavailable; direct replacement degraded")
            client.insertText(output.insertText, replacementRange: .notFound)
            expectedLocation = nil
            return
        }
        let range = NSRange(location: end - output.deleteCount, length: output.deleteCount)
        client.insertText(output.insertText, replacementRange: range)
        expectedLocation = range.location + output.insertText.utf16.count
    }

    func commit(_ text: String, to client: any IMKTextInput) {
        expectedLocation = nil
        shownWord = ""
    }

    /// `nil` when the app can't return its text.
    private func wordEnds(at location: Int, in client: any IMKTextInput) -> Bool? {
        let length = shownWord.utf16.count
        guard location >= length else { return false }
        guard let text = client.string(from: NSRange(location: location - length, length: length), actualRange: nil) else {
            return nil
        }
        return text == shownWord
    }

    private func knownCaret(of client: any IMKTextInput) -> Int? {
        let caret = client.selectedRange().location
        return caret == NSNotFound ? nil : caret
    }
}
