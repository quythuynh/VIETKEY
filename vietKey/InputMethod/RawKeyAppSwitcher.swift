import AppKit
import Carbon
import os

/// Remote desktop / VM apps translate keys with the current input source's key layout, which an
/// input method doesn't have. Switch to the underlying layout while one of them is in front.
final class RawKeyAppSwitcher {
    static let shared = RawKeyAppSwitcher()

    private var switchedFrom: (vietnamese: Bool, layoutID: String)?
    private var observer: NSObjectProtocol?

    func start() {
        guard observer == nil else { return }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleID = app?.bundleIdentifier
            MainActor.assumeIsolated {
                self?.applicationActivated(bundleID)
            }
        }
        applicationActivated(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
    }

    private func applicationActivated(_ bundleID: String?) {
        if StrategyResolver.isRawKeyApp(bundleID) {
            guard switchedFrom == nil, let vietnamese = InputModeSwitcher.currentMode,
                  let layoutID = InputModeSwitcher.selectUnderlyingKeyboardLayout()
            else { return }
            switchedFrom = (vietnamese, layoutID)
            Log.app.info("\(bundleID ?? "?", privacy: .public) is frontmost; switched to \(layoutID, privacy: .public)")
        } else if let previous = switchedFrom {
            switchedFrom = nil
            guard InputModeSwitcher.currentSourceID == previous.layoutID else { return }
            InputModeSwitcher.select(vietnamese: previous.vietnamese)
            Log.app.info("Back from raw-key app; restored VIET")
        }
    }
}
