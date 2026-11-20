import Carbon
import Foundation

enum InputModeSwitcher {
    static let vietnameseModeID = AppIdentity.vietnameseModeID
    static let englishModeID = AppIdentity.englishModeID

    static func isVietnamese(modeID: String) -> Bool? {
        switch modeID {
        case vietnameseModeID: true
        case englishModeID: false
        default: nil
        }
    }

    static var currentMode: Bool? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let id = stringProperty(source, kTISPropertyInputSourceID)
        else { return nil }
        return isVietnamese(modeID: id)
    }

    static var currentSourceID: String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return stringProperty(source, kTISPropertyInputSourceID)
    }

    static func selectUnderlyingKeyboardLayout() -> String? {
        guard let layout = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let id = stringProperty(layout, kTISPropertyInputSourceID),
              TISSelectInputSource(layout) == noErr
        else { return nil }
        return id
    }

    @discardableResult
    static func select(vietnamese: Bool) -> Bool {
        guard let source = source(id: vietnamese ? vietnameseModeID : englishModeID) else { return false }
        return TISSelectInputSource(source) == noErr
    }

    static func source(id: String) -> TISInputSource? {
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]
        return sources?.first
    }

    static func isEnabled(_ source: TISInputSource) -> Bool {
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue())
    }

    private static func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }
}

protocol InputModeSelecting {
    func select(vietnamese: Bool)
}

struct SystemInputModeSelector: InputModeSelecting {
    func select(vietnamese: Bool) {
        InputModeSwitcher.select(vietnamese: vietnamese)
    }
}

final class ModeState {
    static let shared = ModeState(isVietnamese: InputModeSwitcher.currentMode ?? true)
    var isVietnamese: Bool

    init(isVietnamese: Bool) {
        self.isVietnamese = isVietnamese
    }
}

/// Clients found to ignore marked text during this session, shared by all controllers.
final class RawKeyClientRegistry {
    static let shared = RawKeyClientRegistry()
    private var ids: Set<String> = []

    func contains(_ id: String?) -> Bool {
        id.map(ids.contains) ?? false
    }

    func insert(_ id: String?) {
        if let id { ids.insert(id) }
    }
}
