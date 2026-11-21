import AppKit
import InputMethodKit
import os
import VietEngine

/// Typing state and logic for one IMK client.
final class InputSession {
    let settings: AppSettings
    private let modeState: ModeState
    private let modeSelector: any InputModeSelecting
    private let rawKeyClients: RawKeyClientRegistry

    private var engine = VietEngine()
    private var engineRevision = -1
    private let output = OutputSelector()
    private var hotkeyMonitor = HotkeyMonitor()
    private(set) var clientBundleID: String?
    private var composingClientID: String?
    private var activeClientID: String?
    private var markedTextVerifiedClientIDs: Set<String> = []
    private var menuCache: (key: String, menu: NSMenu)?

    init(
        settings: AppSettings = .shared,
        modeState: ModeState = .shared,
        modeSelector: any InputModeSelecting = SystemInputModeSelector(),
        rawKeyClients: RawKeyClientRegistry = .shared
    ) {
        self.settings = settings
        self.modeState = modeState
        self.modeSelector = modeSelector
        self.rawKeyClients = rawKeyClients
    }

    func activate(_ client: (any IMKTextInput)?) {
        clientBundleID = client?.bundleIdentifier()
        let clientID = client?.uniqueClientIdentifierString()
        activeClientID = clientID
        Log.input.info("activate client=\(self.clientBundleID ?? "?", privacy: .public) composing=\(self.engine.isComposing)")

        // IMK may re-activate the same client mid-word; keep the word then.
        if engine.isComposing && clientID != composingClientID {
            engine.reset()
        }
        reloadSettings()
        restoreModeForCurrentApp()
    }

    func deactivate(_ client: (any IMKTextInput)?) {
        Log.input.info("deactivate composing=\(self.engine.isComposing)")
        commit(client)
    }

    func commit(_ client: (any IMKTextInput)?) {
        let text = engine.commitAsShown()
        composingClientID = nil
        #if DEBUG
        if !text.isEmpty {
            Log.input.debug("commit '\(text, privacy: .public)'")
        }
        #endif
        if let client {
            output.strategy.commit(text, to: client)
        }
    }

    /// Returns false when `value` isn't one of VIET's input modes.
    func setMode(_ modeID: String?, client: (any IMKTextInput)?) -> Bool {
        guard let modeID, let vietnamese = InputModeSwitcher.isVietnamese(modeID: modeID) else {
            return false
        }
        guard vietnamese != modeState.isVietnamese else { return true }
        commit(client)
        modeState.isVietnamese = vietnamese
        rememberMode(vietnamese)
        return true
    }

    func handle(_ event: NSEvent, client: any IMKTextInput) -> Bool {
        if hotkeyMonitor.handle(event, hotkey: settings.hotkey) {
            toggleMode(client)
            return event.type == .keyDown
        }
        // Every call into the client is a round trip to a possibly busy app: keep them off the
        // path of keys VIET doesn't handle, and ask for the client's ID once per activation.
        guard event.type == .keyDown, modeState.isVietnamese, !settings.isExcluded(clientBundleID),
              !StrategyResolver.isRawKeyApp(clientBundleID)
        else {
            return false
        }
        let clientID = activeClientID ?? client.uniqueClientIdentifierString()
        activeClientID = clientID
        guard !rawKeyClients.contains(clientID) else { return false }

        if settings.revision != engineRevision {
            if engine.options != settings.engineOptions {
                commit(client)
            }
            reloadSettings()
        }

        switch KeyEventMapper.map(event) {
        case .commitAndPass:
            commit(client)
            return false
        case .engine(let key):
            if engine.isComposing && !output.strategy.isInSync(with: client) {
                engine.reset()
                output.wordWasLost(clientID: clientID, bundleID: clientBundleID)
            }
            if !engine.isComposing {
                output.checkCaret(of: client, clientID: clientID)
            }
            let result = engine.process(key)
            composingClientID = engine.isComposing ? clientID : nil
            output.strategy.apply(result, to: client)

            // The app ignores marked text (remote desktop, games): hand the key back and pass keys through.
            if output.mode == .markedText, result.consumed, !result.composing.isEmpty,
               !markedTextVerifiedClientIDs.contains(clientID ?? ""),
               !markedTextShows(in: client, clientID: clientID) {
                Log.input.notice("\(self.clientBundleID ?? "?", privacy: .public) ignores marked text; passing keys through")
                engine.reset()
                composingClientID = nil
                rawKeyClients.insert(clientID)
                return false
            }
            #if DEBUG
            Log.input.debug("key \(String(describing: key), privacy: .public) → consumed=\(result.consumed) composing='\(result.composing, privacy: .public)' commit='\(result.commitText, privacy: .public)'")
            #endif
            return result.consumed
        }
    }

    private func toggleMode(_ client: any IMKTextInput) {
        commit(client)
        let vietnamese = !modeState.isVietnamese
        modeState.isVietnamese = vietnamese
        rememberMode(vietnamese)
        modeSelector.select(vietnamese: vietnamese)
        Log.input.info("Switched to \(vietnamese ? "Vietnamese" : "English", privacy: .public)")
    }

    private func rememberMode(_ vietnamese: Bool) {
        guard settings.rememberModePerApp, let clientBundleID, settings.appModes[clientBundleID] != vietnamese else { return }
        settings.appModes[clientBundleID] = vietnamese
    }

    private func restoreModeForCurrentApp() {
        guard settings.rememberModePerApp, let clientBundleID,
              let stored = settings.appModes[clientBundleID], stored != modeState.isVietnamese
        else { return }
        modeState.isVietnamese = stored
        // Selecting an input source during activation can re-enter IMK.
        let modeSelector = modeSelector
        Task { @MainActor in
            modeSelector.select(vietnamese: stored)
        }
    }

    /// Checked once per client: whether the app displays the marked text we set.
    private func markedTextShows(in client: any IMKTextInput, clientID: String?) -> Bool {
        guard client.markedRange().location != NSNotFound else { return false }
        if let clientID { markedTextVerifiedClientIDs.insert(clientID) }
        return true
    }

    func menu(target: VKInputController) -> NSMenu {
        let key = "\(settings.revision)|\(clientBundleID ?? "")"
        if let menuCache, menuCache.key == key { return menuCache.menu }
        let menu = IMMenu.make(target: target, session: self)
        menuCache = (key, menu)
        return menu
    }

    /// Uses only the bundle ID: activation must not wait on the client app.
    private func reloadSettings() {
        engine.options = settings.engineOptions
        engineRevision = settings.revision
        output.reload(StrategyResolver.mode(for: clientBundleID, settings: settings), clientID: activeClientID)
    }
}
