import InputMethodKit
import os
import VietEngine

final class DirectReplaceStrategy: OutputStrategy {
    /// Where the current word ends on screen, and the word as written there.
    private var expectedLocation: Int?
    private var shownWord = ""
    /// Whether the app ever showed a word we wrote. Terminals in Electron apps hand each letter
    /// to the shell and clear their field, so there is never anything to replace.
    private(set) var keepsWrittenText = false

    /// The word is still being typed if the caret sits right after what we wrote. When the caret
    /// isn't where we expected (the location we computed from a stale caret, e.g. right after a
    /// chat app cleared its field), the text before it decides.
    func isInSync(with client: any IMKTextInput) -> Bool {
        guard !shownWord.isEmpty else { return true }
        let caret = client.selectedRange().location
        guard caret != NSNotFound else { return false }
        if caret != expectedLocation {
            guard wordEnds(at: caret, in: client) == true else { return false }
            expectedLocation = caret
        }
        keepsWrittenText = true
        return true
    }

    func apply(_ output: EngineOutput, to client: any IMKTextInput) {
        defer {
            shownWord = output.consumed ? output.composing : ""
            if !output.consumed { expectedLocation = nil }
        }
        guard output.deleteCount > 0 || !output.insertText.isEmpty else { return }

        // Nothing to delete: insert at the app's own caret, a reported one may be stale. Mid-word
        // the caret was just checked by `isInSync`, so it isn't asked for again.
        guard output.deleteCount > 0 else {
            let caret = expectedLocation ?? caretIfKnown(of: client)
            client.insertText(output.insertText, replacementRange: .notFound)
            expectedLocation = caret.map { $0 + output.insertText.utf16.count }
            return
        }

        guard let end = expectedLocation ?? caretIfKnown(of: client), end >= output.deleteCount else {
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
        // IMK writes through `actualRange` without a nil check, so it must point somewhere.
        var actualRange = NSRange()
        let range = NSRange(location: location - length, length: length)
        guard let text = client.string(from: range, actualRange: &actualRange) else { return nil }
        return text == shownWord
    }

    private func caretIfKnown(of client: any IMKTextInput) -> Int? {
        let caret = client.selectedRange().location
        return caret == NSNotFound ? nil : caret
    }
}
