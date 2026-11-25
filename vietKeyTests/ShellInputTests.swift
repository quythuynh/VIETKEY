import AppKit
import Testing
@testable import vietKey
import VietEngine

@Suite("Shell terminals")
struct ShellInputTests {
    let settings = makeSettings()

    func makeSession() -> InputSession {
        InputSession(settings: settings, modeState: ModeState(isVietnamese: true), modeSelector: FakeModeSelector(),
                     rawKeyClients: RawKeyClientRegistry())
    }

    func makeTerminal() -> FakeTextClient {
        let client = FakeTextClient(bundleID: "com.apple.Terminal")
        client.actsAsShell = true
        return client
    }

    func type(_ input: String, into client: FakeTextClient, with session: InputSession) {
        for character in input where !session.handle(KeyEvents.key(character), client: client) {
            client.receiveUnhandledKey(character)
        }
    }

    @Test func shellSeesEachLetterAsTyped() {
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("xin chaof", into: client, with: session)
        #expect(client.text == "xin chào")
        #expect(client.marked.isEmpty)
    }

    @Test func enterReachesTheShellRightAfterTheWord() {
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("tieesng vieetj⏎", into: client, with: session)
        #expect(client.text == "tiếng việt⏎")
    }

    @Test func returnHandledByTheTerminalEndsTheWord() {
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("thao tacs", into: client, with: session)
        // With nothing marked, Terminal sends Return to the shell without asking the input method.
        client.insertText("\n", replacementRange: .notFound)
        type("thao", into: client, with: session)
        #expect(client.text == "thao tác\nthao")
    }

    @Test func shellCompletionEndsTheWord() {
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("cd Docu", into: client, with: session)
        // Tab completion, done by the shell without the input method seeing Tab.
        client.insertText("ments/", replacementRange: .notFound)
        type("as", into: client, with: session)
        #expect(client.text == "cd Documents/á")
    }

    @Test func terminalWithoutCaretKeepsTheWord() {
        let session = makeSession(), client = makeTerminal()
        client.reportsCaret = false
        session.activate(client)
        type("vieetj", into: client, with: session)
        #expect(client.text == "việt")
    }

    @Test func backspaceInsideWordUsesTheTerminalsOwn() {
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("vieet⌫ts", into: client, with: session)
        #expect(client.text == "viết")
    }

    @Test func markedTextSettingStillApplies() {
        settings.outputMode = .markedText
        let session = makeSession(), client = makeTerminal()
        session.activate(client)
        type("chaof", into: client, with: session)
        #expect(client.marked == "chào")
    }
}
