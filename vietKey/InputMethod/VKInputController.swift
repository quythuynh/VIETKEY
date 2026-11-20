@preconcurrency import AppKit
@preconcurrency import InputMethodKit

/// IMK entry point. IMK calls controllers on the main thread, which `assumeIsolated` asserts;
/// all logic lives in the main-actor `InputSession`. IMK proxies aren't Sendable, but they are
/// only used synchronously on that thread, hence the `nonisolated(unsafe)` locals.
@objc(VKInputController)
nonisolated final class VKInputController: IMKInputController {
    private lazy var session = MainActor.assumeIsolated { InputSession() }

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask([.keyDown, .flagsChanged]).rawValue)
    }

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        let session = session
        nonisolated(unsafe) let client = sender as? any IMKTextInput
        MainActor.assumeIsolated { session.activate(client) }
    }

    override func deactivateServer(_ sender: Any!) {
        let session = session
        nonisolated(unsafe) let client = sender as? any IMKTextInput
        MainActor.assumeIsolated { session.deactivate(client) }
        super.deactivateServer(sender)
    }

    override func commitComposition(_ sender: Any!) {
        let session = session
        nonisolated(unsafe) let client = sender as? any IMKTextInput
        MainActor.assumeIsolated { session.commit(client) }
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        let session = session
        nonisolated(unsafe) let client = sender as? any IMKTextInput
        let modeID = value as? String
        let handled = MainActor.assumeIsolated { session.setMode(modeID, client: client) }
        if !handled {
            super.setValue(value, forTag: tag, client: sender)
        }
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, let client = sender as? any IMKTextInput else { return false }
        let session = session
        nonisolated(unsafe) let unsafeEvent = event
        nonisolated(unsafe) let unsafeClient = client
        return MainActor.assumeIsolated { session.handle(unsafeEvent, client: unsafeClient) }
    }

    override func menu() -> NSMenu! {
        let session = session
        nonisolated(unsafe) let target = self
        nonisolated(unsafe) var menu: NSMenu?
        MainActor.assumeIsolated { menu = session.menu(target: target) }
        return menu
    }
}
