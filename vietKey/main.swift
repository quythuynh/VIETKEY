import AppKit
import InputMethodKit
import os

let app = NSApplication.shared

if AppIdentity.isTestHost {
    app.run()
} else if InputSourceInstaller.isRunningFromInstallLocation {
    let connectionName = AppIdentity.connectionName
    guard let server = IMKServer(name: connectionName, bundleIdentifier: AppIdentity.bundleID) else {
        Log.app.fault("Could not start IMKServer '\(connectionName, privacy: .public)'")
        exit(1)
    }
    Log.app.info("VIET input method started")
    RawKeyAppSwitcher.shared.start()
    QuickInputController.shared.start()

    withExtendedLifetime(server) {
        app.run()
    }
} else {
    Log.app.info("Running outside Input Methods; showing installer")
    SettingsWindowController.shared.show(tab: .general)
    app.run()
}
