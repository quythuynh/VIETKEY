import Foundation
import InputMethodKit

enum StrategyResolver {
    /// Terminals and editors with their own text engine, which can't replace text before the cursor.
    static let markedTextOnlyPrefixes = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.",
        "com.mitchellh.ghostty",
        "com.jetbrains.",
        "com.google.android.studio",
        "com.sublimetext.",
    ]

    /// Apps that forward raw keys to another computer.
    static let rawKeyAppPrefixes = [
        "com.teamviewer.",
        "com.philandro.anydesk",
        "com.apple.ScreenSharing",
        "com.microsoft.rdc.",
        "com.carriez.rustdesk",
        "com.realvnc.",
        "com.p5sys.jump.",
        "com.citrix.",
        "com.parallels.",
        "com.vmware.",
        "com.utmapp.",
        "org.virtualbox.",
    ]

    static func isRawKeyApp(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return rawKeyAppPrefixes.contains(where: bundleID.hasPrefix)
    }

    /// Direct replacement needs the caret position; clients that can't report it get marked text.
    static func mode(for client: (any IMKTextInput)?, settings: AppSettings) -> OutputMode {
        let mode = mode(for: client?.bundleIdentifier(), settings: settings)
        if mode == .directReplace, let client, client.selectedRange().location == NSNotFound {
            return .markedText
        }
        return mode
    }

    static func mode(for bundleID: String?, settings: AppSettings) -> OutputMode {
        if let bundleID, let override = settings.appOutputModes[bundleID] {
            return override
        }
        if settings.outputMode == .directReplace, let bundleID,
           markedTextOnlyPrefixes.contains(where: bundleID.hasPrefix) {
            return .markedText
        }
        return settings.outputMode
    }

    static func makeStrategy(for mode: OutputMode) -> any OutputStrategy {
        switch mode {
        case .markedText: MarkedTextStrategy()
        case .directReplace: DirectReplaceStrategy()
        }
    }
}
