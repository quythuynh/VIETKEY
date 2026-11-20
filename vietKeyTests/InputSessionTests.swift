import AppKit
import Testing
@testable import vietKey
import VietEngine

@Suite("Input session")
struct InputSessionTests {
    let settings = makeSettings()
    let modeState = ModeState(isVietnamese: true)
    let selector = FakeModeSelector()
    let rawKeyClients = RawKeyClientRegistry()

    func makeSession() -> InputSession {
        InputSession(settings: settings, modeState: modeState, modeSelector: selector, rawKeyClients: rawKeyClients)
    }

    /// Types into `client` the way the system would: keys the session doesn't consume reach the app.
    func type(_ input: String, into client: FakeTextClient, with session: InputSession) {
        for character in input where !session.handle(KeyEvents.key(character), client: client) {
            client.receiveUnhandledKey(character)
        }
    }

    @Test func typesWithMarkedText() {
        settings.outputMode = .markedText
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("Tieengs Vieejt raast ddepj ", into: client, with: session)
        #expect(client.screen == "Tiếng Việt rất đẹp ")
        #expect(client.marked.isEmpty)
    }

    @Test func reactivatingSameClientKeepsWord() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("tie", into: client, with: session)
        session.activate(client)
        type("nef ", into: client, with: session)
        #expect(client.screen == "tiền ")
    }

    @Test func deactivationCommitsWord() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("vieejt", into: client, with: session)
        session.deactivate(client)
        #expect(client.text == "việt")
        #expect(client.marked.isEmpty)
    }

    @Test func directReplaceIsTheDefault() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("vieejt nam ", into: client, with: session)
        #expect(client.text == "việt nam ")
        #expect(client.marked.isEmpty)
    }

    @Test func settingsChangeAppliesToNextWord() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("as ", into: client, with: session)
        settings.inputMethod = .vni
        type("a1 ", into: client, with: session)
        #expect(client.screen == "á á ")
    }

    @Test(arguments: ["com.teamviewer.TeamViewer", "com.philandro.anydesk"])
    func rawKeyAppsGetKeysDirectly(bundleID: String) {
        let session = makeSession(), client = FakeTextClient(bundleID: bundleID)
        session.activate(client)
        #expect(!session.handle(KeyEvents.key("a"), client: client))
    }

    @Test func excludedAppsGetKeysDirectly() {
        settings.excludedApps = ["test.excluded"]
        let session = makeSession(), client = FakeTextClient(bundleID: "test.excluded")
        session.activate(client)
        #expect(!session.handle(KeyEvents.key("a"), client: client))
    }

    @Test func enterActsOnFirstPress() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("xin chaof", into: client, with: session)
        #expect(client.marked.isEmpty)
        #expect(!session.handle(KeyEvents.key("⏎"), client: client))
        #expect(client.text == "xin chào")
    }

    @Test func clientWithoutCaretFallsBackToMarkedText() {
        let session = makeSession(), client = FakeTextClient()
        client.reportsCaret = false
        session.activate(client)
        type("as", into: client, with: session)
        #expect(client.marked == "á")
    }

    @Test func clientIgnoringMarkedTextFallsBackToRawKeys() {
        settings.outputMode = .markedText
        let session = makeSession(), client = FakeTextClient()
        client.ignoresMarkedText = true
        session.activate(client)
        type("as", into: client, with: session)
        #expect(client.text == "as")
        #expect(rawKeyClients.contains(client.clientID))
    }

    @Test func hotkeyTogglesToEnglish() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        _ = session.handle(KeyEvents.modifiers([.control, .shift]), client: client)
        _ = session.handle(KeyEvents.modifiers([]), client: client)
        #expect(selector.selections == [false])
        type("as ", into: client, with: session)
        #expect(client.text == "as ")
    }

    @Test func modeIDsFromTheSystem() {
        let session = makeSession(), client = FakeTextClient()
        #expect(session.setMode(InputModeSwitcher.englishModeID, client: client))
        #expect(!modeState.isVietnamese)
        #expect(!session.setMode("com.apple.keylayout.ABC", client: client))
    }

    @Test func modeIsRememberedPerApp() {
        let session = makeSession(), client = FakeTextClient(bundleID: "test.remembered")
        session.activate(client)
        _ = session.setMode(InputModeSwitcher.englishModeID, client: client)
        #expect(settings.appModes["test.remembered"] == false)
    }
}
