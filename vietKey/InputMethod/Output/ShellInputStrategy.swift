import InputMethodKit
import VietEngine

/// For terminals that write inserted text straight to the shell: each letter goes out as it is
/// typed, and a change to the word is sent as DEL characters followed by the new ending, the same
/// bytes as pressing backspace. The shell sees the word at once, so Enter needs no commit step.
final class ShellInputStrategy: OutputStrategy {
    private static let delete = "\u{7F}"

    /// The word as the shell has it.
    private var shownWord = ""
    /// Where the word started in the terminal's text.
    private var wordStart: Int?

    /// Terminal handles Return, Tab and arrows itself when nothing is marked, so the word can end
    /// without us seeing a key. The shell's echo of the latest letters may still be on its way, so
    /// only text the word can't explain counts: a line break, or more than we sent.
    func isInSync(with client: any IMKTextInput) -> Bool {
        guard !shownWord.isEmpty, let wordStart else { return true }
        let caret = client.selectedRange().location
        guard caret != NSNotFound else { return true }
        guard caret < wordStart || !echoFits(NSRange(location: wordStart, length: caret - wordStart), of: client)
        else { return true }
        commit("", to: client)
        return false
    }

    private func echoFits(_ range: NSRange, of client: any IMKTextInput) -> Bool {
        // IMK writes through `actualRange` without a nil check, so it must point somewhere.
        var actualRange = NSRange()
        guard let echo = client.string(from: range, actualRange: &actualRange) else { return true }
        return echo.count <= shownWord.count && !echo.contains(where: \.isNewline)
    }

    func apply(_ output: EngineOutput, to client: any IMKTextInput) {
        defer {
            shownWord = output.consumed ? output.composing : ""
            if shownWord.isEmpty { wordStart = nil }
        }
        guard output.deleteCount > 0 || !output.insertText.isEmpty else { return }
        if shownWord.isEmpty {
            let caret = client.selectedRange().location
            wordStart = caret == NSNotFound ? nil : caret
        }
        let deletes = String(repeating: Self.delete, count: characterCount(ofLast: output.deleteCount))
        client.insertText(deletes + output.insertText, replacementRange: .notFound)
    }

    /// Removing just the last letter is exactly what the terminal's own backspace does.
    func letsAppDelete(_ output: EngineOutput) -> Bool {
        guard output.insertText.isEmpty, let last = shownWord.last,
              output.deleteCount == String(last).utf16.count
        else { return false }
        shownWord = output.composing
        if shownWord.isEmpty { wordStart = nil }
        return true
    }

    func commit(_ text: String, to client: any IMKTextInput) {
        shownWord = ""
        wordStart = nil
    }

    /// The shell deletes characters while the engine counts UTF-16 units.
    private func characterCount(ofLast utf16Count: Int) -> Int {
        var remaining = utf16Count
        var count = 0
        for character in shownWord.reversed() where remaining > 0 {
            remaining -= String(character).utf16.count
            count += 1
        }
        return count
    }
}
