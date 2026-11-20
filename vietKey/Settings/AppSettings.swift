import AppKit
import Observation
import VietEngine

enum OutputMode: String, CaseIterable, Identifiable {
    case markedText
    case directReplace

    var id: String { rawValue }
}

struct Hotkey: Equatable, Codable {
    static let relevantModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]
    static let `default` = Hotkey(keyCode: nil, modifiers: NSEvent.ModifierFlags([.control, .shift]).rawValue, keyLabel: "")
    static let quickInputDefault = Hotkey(keyCode: KeyCode.v, modifiers: NSEvent.ModifierFlags([.control, .option]).rawValue, keyLabel: "V")

    var keyCode: UInt16?
    var modifiers: UInt
    var keyLabel: String

    var modifierFlags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }

    var displayString: String {
        let flags = modifierFlags
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        return text + keyLabel
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var revision = 0

    var inputMethod: InputMethodKind { didSet { save(inputMethod.rawValue, for: .inputMethod) } }
    var toneStyle: ToneStyle { didSet { save(toneStyle.rawValue, for: .toneStyle) } }
    var spellCheck: Bool { didSet { save(spellCheck, for: .spellCheck) } }
    var macrosEnabled: Bool { didSet { save(macrosEnabled, for: .macrosEnabled) } }
    var macros: [String: String] { didSet { save(macros, for: .macros) } }
    var outputMode: OutputMode { didSet { save(outputMode.rawValue, for: .outputMode) } }
    var appOutputModes: [String: OutputMode] {
        didSet { save(appOutputModes.mapValues(\.rawValue), for: .appOutputModes) }
    }
    var excludedApps: [String] { didSet { save(excludedApps, for: .excludedApps) } }
    var rememberModePerApp: Bool { didSet { save(rememberModePerApp, for: .rememberModePerApp) } }
    var appModes: [String: Bool] { didSet { save(appModes, for: .appModes) } }
    var hotkey: Hotkey { didSet { save(try? JSONEncoder().encode(hotkey), for: .hotkey) } }
    var quickInputHotkey: Hotkey { didSet { save(try? JSONEncoder().encode(quickInputHotkey), for: .quickInputHotkey) } }
    var pasteWithControl: Bool { didSet { save(pasteWithControl, for: .pasteWithControl) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        inputMethod = defaults.string(forKey: Key.inputMethod.rawValue).flatMap(InputMethodKind.init) ?? .telex
        toneStyle = defaults.string(forKey: Key.toneStyle.rawValue).flatMap(ToneStyle.init) ?? .new
        spellCheck = defaults.object(forKey: Key.spellCheck.rawValue) as? Bool ?? true
        macrosEnabled = defaults.object(forKey: Key.macrosEnabled.rawValue) as? Bool ?? true
        macros = defaults.dictionary(forKey: Key.macros.rawValue) as? [String: String] ?? [:]
        outputMode = defaults.string(forKey: Key.outputMode.rawValue).flatMap(OutputMode.init) ?? .directReplace
        let storedOutputModes = defaults.dictionary(forKey: Key.appOutputModes.rawValue) as? [String: String] ?? [:]
        appOutputModes = storedOutputModes.compactMapValues(OutputMode.init)
        excludedApps = defaults.stringArray(forKey: Key.excludedApps.rawValue) ?? []
        rememberModePerApp = defaults.object(forKey: Key.rememberModePerApp.rawValue) as? Bool ?? false
        appModes = defaults.dictionary(forKey: Key.appModes.rawValue) as? [String: Bool] ?? [:]
        hotkey = defaults.data(forKey: Key.hotkey.rawValue).flatMap { try? JSONDecoder().decode(Hotkey.self, from: $0) } ?? .default
        quickInputHotkey = defaults.data(forKey: Key.quickInputHotkey.rawValue)
            .flatMap { try? JSONDecoder().decode(Hotkey.self, from: $0) } ?? .quickInputDefault
        pasteWithControl = defaults.object(forKey: Key.pasteWithControl.rawValue) as? Bool ?? false
    }

    var engineOptions: EngineOptions {
        EngineOptions(
            inputMethod: inputMethod,
            toneStyle: toneStyle,
            spellCheck: spellCheck,
            macros: macrosEnabled ? MacroTable(macros) : MacroTable()
        )
    }

    func outputMode(for bundleID: String?) -> OutputMode {
        if let bundleID, let override = appOutputModes[bundleID] { return override }
        return outputMode
    }

    func isExcluded(_ bundleID: String?) -> Bool {
        bundleID.map(excludedApps.contains) ?? false
    }

    private enum Key: String {
        case inputMethod, toneStyle, spellCheck, macrosEnabled, macros, outputMode
        case appOutputModes, excludedApps, rememberModePerApp, appModes, hotkey
        case quickInputHotkey, pasteWithControl
    }

    private func save(_ value: Any?, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
        revision += 1
    }
}
