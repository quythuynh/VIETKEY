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
    private var strategy: any OutputStrategy = MarkedTextStrategy()
    private var strategyMode: OutputMode = .markedText
    private var hotkeyMonitor = HotkeyMonitor()
    private(set) var clientBundleID: String?
    private var composingClientID: String?

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
        Log.input.info("activate client=\(self.clientBundleID ?? "?", privacy: .public) composing=\(self.engine.isComposing)")

        // IMK may re-activate the same client mid-word; keep the word then.
        if engine.isComposing && clientID != composingClientID {
            engine.reset()
        }
        reloadSettings(for: client)
        restoreModeForCurrentApp()
    }

    func deactivate(_ client: (any IMKTextInput)?) {
        Log.input.info("deactivate composing=\(self.engine.isComposing)")
        commit(client)
    }

    func commit(_ client: (any IMKTextInput)?) {
        let text = engine.commit()
        composingClientID = nil
        #if DEBUG
        if !text.isEmpty {
            Log.input.debug("commit '\(text, privacy: .public)'")
        }
        #endif
        if let client {
            strategy.commit(text, to: client)
        }
    }

    /// Returns false when `value` isn't one of VIET's input modes.
    func setMode(_ modeID: String?, client: (any IMKTextInput)?) -> Bool {
        guard let modeID, let vietnamese = InputModeSwitcher.isVietnamese(modeID: modeID) else {
            return false
        }
        if vietnamese != modeState.isVietnamese {
            commit(client)
        }
        modeState.isVietnamese = vietnamese
        rememberMode(vietnamese)
        return true
    }

    func handle(_ event: NSEvent, client: any IMKTextInput) -> Bool {
        if hotkeyMonitor.handle(event, hotkey: settings.hotkey) {
            toggleMode(client)
            return event.type == .keyDown
        }
        let clientID = client.uniqueClientIdentifierString()
        guard event.type == .keyDown, modeState.isVietnamese, !settings.isExcluded(clientBundleID),
              !StrategyResolver.isRawKeyApp(clientBundleID), !rawKeyClients.contains(clientID)
        else {
            return false
        }

        if settings.revision != engineRevision {
            if engine.options != settings.engineOptions {
                commit(client)
            }
            reloadSettings(for: client)
        }

        switch KeyEventMapper.map(event) {
        case .commitAndPass:
            commit(client)
            return false
        case .engine(let key):
            if engine.isComposing && !strategy.isInSync(with: client) {
                engine.reset()
            }
            let output = engine.process(key)
            composingClientID = engine.isComposing ? clientID : nil
            strategy.apply(output, to: client)

            // The app ignores marked text (remote desktop, games): hand the key back and pass keys through.
            if strategyMode == .markedText, output.consumed, !output.composing.isEmpty,
               client.markedRange().location == NSNotFound {
                Log.input.notice("\(self.clientBundleID ?? "?", privacy: .public) ignores marked text; passing keys through")
                engine.reset()
                composingClientID = nil
                rawKeyClients.insert(clientID)
                return false
            }
            #if DEBUG
            Log.input.debug("key \(String(describing: key), privacy: .public) → consumed=\(output.consumed) composing='\(output.composing, privacy: .public)' commit='\(output.commitText, privacy: .public)'")
            #endif
            return output.consumed
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

    private func reloadSettings(for client: (any IMKTextInput)?) {
        engine.options = settings.engineOptions
        engineRevision = settings.revision
        let mode = StrategyResolver.mode(for: client, settings: settings)
        if mode != strategyMode {
            strategy = StrategyResolver.makeStrategy(for: mode)
            strategyMode = mode
        }
    }
}
