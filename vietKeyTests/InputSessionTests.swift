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

    @Test func typingContinuesAfterTheAppClearsTheField() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("xin chaof", into: client, with: session)
        _ = session.handle(KeyEvents.key("⏎"), client: client)
        client.text = ""
        client.caret = 0
        client.staleCaret = 8
        type("vieejt nam ", into: client, with: session)
        #expect(client.text == "việt nam ")
    }

    @Test(arguments: ["ddi", "dduwowngf", "nguwowif", "quas"])
    func firstWordAfterSendingKeepsItsMarks(word: String) {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("xin chaof", into: client, with: session)
        _ = session.handle(KeyEvents.key("⏎"), client: client)
        client.text = ""
        client.caret = 0
        client.staleCaret = 9
        type(word + " ", into: client, with: session)
        #expect(client.text == TypingSimulatorReference.type(word) + " ")
    }

    @Test func backspaceRemovingTheLastLetterIsLeftToTheApp() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("vieejt", into: client, with: session)
        #expect(!session.handle(KeyEvents.key("⌫"), client: client))
        client.receiveUnhandledKey("⌫")
        type("⌫eejt ", into: client, with: session)
        #expect(client.text == "việt ")
    }

    @Test(arguments: ["toans⌫", "hoaf⌫", "nguwowif⌫⌫", "thuowngf⌫⌫⌫", "ass⌫", "as⌫b", "dduwowngf⌫⌫⌫⌫⌫⌫⌫"])
    func backspaceInWordMatchesTheEngine(input: String) {
        for mode in [OutputMode.directReplace, .markedText] {
            settings.outputMode = mode
            let session = makeSession(), client = FakeTextClient()
            session.activate(client)
            type(input + " ", into: client, with: session)
            #expect(client.screen == TypingSimulatorReference.type(input) + " ", "\(mode)")
        }
    }

    @Test func clientWithoutCaretFallsBackToMarkedText() {
        let session = makeSession(), client = FakeTextClient()
        client.reportsCaret = false
        session.activate(client)
        type("as", into: client, with: session)
        #expect(client.marked == "á")
    }

    @Test func clientForwardingTextFallsBackToMarkedText() {
        let session = makeSession(), client = FakeTextClient()
        client.forwardsText = true
        session.activate(client)
        type("khi suwr dungj tren app mowis ", into: client, with: session)
        #expect(client.screen == "khi sử dụng tren app mới ")
        session.activate(client)
        type("vieejt ", into: client, with: session)
        #expect(client.screen.hasSuffix(" việt "))
    }

    @Test func clickingElsewhereKeepsDirectReplacement() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("xin ch", into: client, with: session)
        client.caret = 0
        type("as ", into: client, with: session)
        #expect(client.text == "á xin ch")
        #expect(client.marked.isEmpty)
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

    @Test func activationDoesNotWaitOnTheApp() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        session.activate(client)
        #expect(client.caretQueries == 0)
    }

    @Test func typingAsksTheAppOnlyWhatItNeeds() {
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        let keys = "Tieengs Vieejt raast ddepj "
        type(keys, into: client, with: session)
        #expect(client.clientIDQueries == 1)
        // At most one caret query per key, plus one per client to check the app reports it.
        #expect(client.caretQueries <= keys.count + 1)
    }

    @Test func englishModeDoesNotQueryTheApp() {
        modeState.isVietnamese = false
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        let before = (client.clientIDQueries, client.caretQueries)
        type("hello world ", into: client, with: session)
        #expect(client.clientIDQueries == before.0)
        #expect(client.caretQueries == before.1)
    }

    @Test func markedTextIsVerifiedOncePerClient() {
        settings.outputMode = .markedText
        let session = makeSession(), client = FakeTextClient()
        session.activate(client)
        type("Tieengs Vieejt ", into: client, with: session)
        #expect(client.markedRangeQueries == 1)
    }

    @Test func modeIsNotRememberedByDefault() {
        let session = makeSession(), client = FakeTextClient(bundleID: "test.default")
        session.activate(client)
        _ = session.setMode(InputModeSwitcher.englishModeID, client: client)
        #expect(settings.appModes.isEmpty)
    }

    @Test func modeIsRememberedPerApp() {
        settings.rememberModePerApp = true
        let session = makeSession(), client = FakeTextClient(bundleID: "test.remembered")
        session.activate(client)
        _ = session.setMode(InputModeSwitcher.englishModeID, client: client)
        #expect(settings.appModes["test.remembered"] == false)
    }
}
