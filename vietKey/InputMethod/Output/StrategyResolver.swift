import Foundation

enum StrategyResolver {
    /// Terminals and editors with their own text engine, which can't replace text before the cursor.
    /// Other apps that drop typed text are detected while typing (`OutputSelector`).
    static let markedTextOnlyPrefixes = [
        "com.googlecode.iterm2",
        "dev.warp.",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "org.alacritty",
        "com.github.wez.wezterm",
        "co.zeit.hyper",
        "org.tabby",
        "com.stablyai.orca",
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

    /// Terminals whose inserted text goes to the shell byte for byte, control characters included.
    static let shellInputPrefixes = [
        "com.apple.Terminal",
    ]

    static func isShellTerminal(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return shellInputPrefixes.contains(where: bundleID.hasPrefix)
    }

    static func makeStrategy(for mode: OutputMode, bundleID: String?) -> any OutputStrategy {
        switch mode {
        case .markedText: MarkedTextStrategy()
        case .directReplace: isShellTerminal(bundleID) ? ShellInputStrategy() : DirectReplaceStrategy()
        }
    }
}
