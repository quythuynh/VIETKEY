import AppKit
import Carbon
import os

enum InputSourceInstaller {
    private static let installFolder = "Library/Input Methods"
    private static let keyboardSettingsURL = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")

    static var installDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: installFolder, directoryHint: .isDirectory)
    }

    static var installedAppURL: URL {
        installDirectory.appending(path: Bundle.main.bundleURL.lastPathComponent)
    }

    static var isRunningFromInstallLocation: Bool {
        Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL
            == installedAppURL.resolvingSymlinksInPath().standardizedFileURL
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: installedAppURL.path)
    }

    static var isEnabled: Bool {
        guard let source = InputModeSwitcher.source(id: InputModeSwitcher.vietnameseModeID) else { return false }
        return InputModeSwitcher.isEnabled(source)
    }

    static func install() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)

        let runningOldCopies = NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.bundleID)
            .filter { $0 != .current }
        runningOldCopies.forEach { $0.terminate() }

        if fileManager.fileExists(atPath: installedAppURL.path) {
            try fileManager.removeItem(at: installedAppURL)
        }
        try fileManager.copyItem(at: Bundle.main.bundleURL, to: installedAppURL)

        let status = TISRegisterInputSource(installedAppURL as CFURL)
        if status != noErr {
            Log.app.error("TISRegisterInputSource failed: \(status)")
        }
        enable()
        Log.app.info("Installed to \(installedAppURL.path, privacy: .public)")
    }

    static func enable() {
        for id in [InputModeSwitcher.vietnameseModeID, InputModeSwitcher.englishModeID] {
            if let source = InputModeSwitcher.source(id: id), !InputModeSwitcher.isEnabled(source) {
                TISEnableInputSource(source)
            }
        }
    }

    static func openKeyboardSettings() {
        if let url = keyboardSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}
