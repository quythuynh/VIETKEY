import InputMethodKit
import os

/// Picks how text reaches the client: the configured mode, or marked text for clients whose
/// text can't be replaced.
final class OutputSelector {
    private(set) var strategy: any OutputStrategy = MarkedTextStrategy()
    private(set) var mode: OutputMode = .markedText
    private var bundleID: String?
    private var caretCheckedClientID: String?
    /// Learned while typing; outlives reactivation so each client is only learned once.
    private var markedTextClientIDs: Set<String> = []

    func reload(_ configured: OutputMode, clientID: String?, bundleID: String?) {
        caretCheckedClientID = nil
        use(markedTextClientIDs.contains(clientID ?? "") ? .markedText : configured, bundleID: bundleID)
    }

    /// Direct replacement needs the caret position; checked once per client, when typing starts.
    func checkCaret(of client: any IMKTextInput, clientID: String?) {
        guard strategy is DirectReplaceStrategy, caretCheckedClientID != clientID else { return }
        caretCheckedClientID = clientID
        if client.selectedRange().location == NSNotFound {
            use(.markedText, bundleID: bundleID)
        }
    }

    /// Called when the word we wrote isn't before the caret. Terminals in Electron apps hand each
    /// letter to the shell and clear their field: a client that never kept a word gets marked text.
    func wordWasLost(clientID: String?, bundleID: String?) {
        guard let direct = strategy as? DirectReplaceStrategy, !direct.keepsWrittenText else { return }
        Log.input.notice("\(bundleID ?? "?", privacy: .public) doesn't keep typed text; using marked text")
        markedTextClientIDs.insert(clientID ?? "")
        use(.markedText, bundleID: bundleID)
    }

    private func use(_ newMode: OutputMode, bundleID newBundleID: String?) {
        guard newMode != mode || newBundleID != bundleID else { return }
        strategy = StrategyResolver.makeStrategy(for: newMode, bundleID: newBundleID)
        mode = newMode
        bundleID = newBundleID
    }
}
