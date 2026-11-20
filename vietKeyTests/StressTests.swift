import AppKit
import Testing
@testable import vietKey
import VietEngine

/// Long random sessions: typing, Backspace, Enter, app switches, mode toggles and setting changes.
@Suite("Stress")
struct StressTests {
    private enum Action {
        case key(Character)
        case switchClient
        case toggleMode
        case changeMethod
        case click(UInt64)
        case sendMessage
    }

    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private static let keys = Array("aeiouydwsfrxjztnghcmpqlv aeiouwsfrxj⌫⏎,.")

    private func randomActions(seed: UInt64, count: Int) -> [Action] {
        var generator = SeededGenerator(state: seed)
        return (0..<count).map { _ in
            switch Int.random(in: 0..<100, using: &generator) {
            case 0..<3: .switchClient
            case 3..<4: .toggleMode
            case 4..<5: .changeMethod
            case 5..<8: .click(generator.next())
            case 8..<10: .sendMessage
            default: .key(Self.keys.randomElement(using: &generator)!)
            }
        }
    }

    /// Runs the actions against two clients and returns their final text.
    private func run(_ actions: [Action], outputMode: OutputMode) -> [String] {
        let settings = makeSettings()
        settings.outputMode = outputMode
        let session = InputSession(settings: settings, modeState: ModeState(isVietnamese: true),
                                   modeSelector: FakeModeSelector(), rawKeyClients: RawKeyClientRegistry())
        let clients = [FakeTextClient(clientID: "A"), FakeTextClient(clientID: "B")]
        var current = 0
        session.activate(clients[current])

        for action in actions {
            let client = clients[current]
            switch action {
            case .key(let character):
                if !session.handle(KeyEvents.key(character), client: client) {
                    client.receiveUnhandledKey(character)
                }
            case .switchClient:
                session.deactivate(client)
                current = 1 - current
                session.activate(clients[current])
            case .toggleMode:
                _ = session.handle(KeyEvents.modifiers([.control, .shift]), client: client)
                _ = session.handle(KeyEvents.modifiers([]), client: client)
            case .changeMethod:
                settings.inputMethod = settings.inputMethod == .telex ? .vni : .telex
            case .sendMessage:
                // A chat app sends on Enter, clears its field and briefly reports the old caret.
                if !session.handle(KeyEvents.key("⏎"), client: client) { client.receiveUnhandledKey("⏎") }
                client.staleCaret = client.caret
                client.text = ""
                client.caret = 0
            case .click(let position):
                // Apps commit marked text on a click; direct replacement notices the moved caret itself.
                if outputMode == .markedText { session.commit(client) }
                client.caret = Int(position % UInt64((client.text as NSString).length + 1))
            }
            #expect(client.caret >= 0 && client.caret <= (client.text as NSString).length)
        }
        session.deactivate(clients[current])
        for client in clients {
            #expect(client.marked.isEmpty, "marked text left behind")
        }
        return clients.map(\.text)
    }

    @Test(arguments: [1, 2, 3, 42, 2026] as [UInt64])
    func outputModesAgree(seed: UInt64) {
        let actions = randomActions(seed: seed, count: 3_000)
        #expect(run(actions, outputMode: .directReplace) == run(actions, outputMode: .markedText))
    }

    @Test func fiftyThousandActionsStayFast() {
        let actions = randomActions(seed: 7, count: 50_000)
        let elapsed = ContinuousClock().measure {
            _ = run(actions, outputMode: .directReplace)
        }
        #expect(elapsed < .seconds(10), "\(elapsed)")
    }

    @Test(arguments: ["vieej", "nguwow", "tuoo", "khoa"])
    func switchingMidWordKeepsWhatIsShown(word: String) {
        let actions = word.map { Action.key($0) } + [.switchClient]
        #expect(run(actions, outputMode: .directReplace) == run(actions, outputMode: .markedText))
    }
}
