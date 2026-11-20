import AppKit
import Observation

/// Opens the quick input panel on the global shortcut, then copies and pastes the text into
/// the app that was in front (TeamViewer and similar apps sync the clipboard to the remote side).
final class QuickInputController: NSObject, NSWindowDelegate {
    static let shared = QuickInputController()

    private let settings: AppSettings
    private let hotkey: GlobalHotkey
    private lazy var panel = makePanel()
    private var targetApp: NSRunningApplication?

    private enum Delay {
        /// The app needs a moment to become active before it receives the paste shortcut.
        static let paste: TimeInterval = 0.3
        static let copiedNotice: TimeInterval = 1.2
    }

    init(settings: AppSettings = .shared, hotkey: GlobalHotkey = .shared) {
        self.settings = settings
        self.hotkey = hotkey
    }

    func start() {
        hotkey.action = { [weak self] in self?.toggle() }
        trackHotkey()
    }

    func toggle() {
        panel.isVisible ? returnToTargetApp() : show()
    }

    func show() {
        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != NSRunningApplication.current.processIdentifier {
            targetApp = front
        }
        panel.textView.prepare(options: settings.engineOptions)
        panel.hint = defaultHint()
        NSApp.activate()
        panel.present()
    }

    func windowWillClose(_ notification: Notification) {
        activateTargetApp()
    }

    private func send() {
        let text = panel.textView.finishedText()
        guard !text.isEmpty else {
            returnToTargetApp()
            return
        }
        Paster.copy(text)

        guard Paster.isTrusted else {
            panel.hint = String(localized: "Copied. Press the paste shortcut in the app to insert it.")
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.copiedNotice) { [weak self] in self?.returnToTargetApp() }
            return
        }
        returnToTargetApp()
        let withControl = settings.pasteWithControl
        DispatchQueue.main.asyncAfter(deadline: .now() + Delay.paste) {
            Paster.paste(withControl: withControl)
        }
    }

    private func returnToTargetApp() {
        panel.orderOut(nil)
        activateTargetApp()
    }

    private func activateTargetApp() {
        if let targetApp, !targetApp.isTerminated {
            targetApp.activate()
        }
    }

    private func defaultHint() -> String {
        let name = targetApp?.localizedName ?? String(localized: "the previous app")
        return String(localized: "Enter: paste into \(name)  ·  ⇧Enter: new line  ·  Esc: cancel")
    }

    private func makePanel() -> QuickInputPanel {
        let panel = QuickInputPanel()
        panel.delegate = self
        panel.textView.onSend = { [weak self] in self?.send() }
        panel.textView.onCancel = { [weak self] in self?.returnToTargetApp() }
        return panel
    }

    private func trackHotkey() {
        withObservationTracking {
            hotkey.register(settings.quickInputHotkey)
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackHotkey() }
        }
    }
}
