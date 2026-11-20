import AppKit
import Carbon
import Testing
@testable import vietKey
import VietEngine

@Suite("Key mapping")
struct KeyEventMapperTests {
    @Test func lettersAndBackspaceGoToTheEngine() {
        #expect(KeyEventMapper.map(KeyEvents.key("a")) == .engine(.character("a")))
        #expect(KeyEventMapper.map(KeyEvents.key("A", flags: .shift)) == .engine(.character("A")))
        #expect(KeyEventMapper.map(KeyEvents.key("⌫")) == .engine(.backspace))
    }

    @Test func shortcutsAndArrowsEndTheWord() {
        #expect(KeyEventMapper.map(KeyEvents.key("c", flags: .command)) == .commitAndPass)
        #expect(KeyEventMapper.map(KeyEvents.key("a", flags: .control)) == .commitAndPass)
        #expect(KeyEventMapper.map(KeyEvents.key("\u{F702}")) == .commitAndPass)
        #expect(KeyEventMapper.map(KeyEvents.key("\u{1B}")) == .commitAndPass)
    }
}

@Suite("V/E hotkey")
struct HotkeyMonitorTests {
    @Test func modifiersAloneFireOnRelease() {
        var monitor = HotkeyMonitor()
        let events = [KeyEvents.modifiers(.control), KeyEvents.modifiers([.control, .shift]),
                      KeyEvents.modifiers(.shift), KeyEvents.modifiers([])]
        let fired = events.map { monitor.handle($0, hotkey: .default) }
        #expect(fired == [false, false, false, true])
    }

    @Test func anotherKeyCancelsModifierHotkey() {
        var monitor = HotkeyMonitor()
        _ = monitor.handle(KeyEvents.modifiers([.control, .shift]), hotkey: .default)
        _ = monitor.handle(KeyEvents.key("a", flags: [.control, .shift]), hotkey: .default)
        let fired = monitor.handle(KeyEvents.modifiers([]), hotkey: .default)
        #expect(!fired)
    }

    @Test func keyHotkeyNeedsExactModifiers() {
        var monitor = HotkeyMonitor()
        let hotkey = Hotkey(keyCode: UInt16(kVK_ANSI_A), modifiers: NSEvent.ModifierFlags.option.rawValue, keyLabel: "A")
        let exact = monitor.handle(KeyEvents.key("a", flags: .option), hotkey: hotkey)
        let extraShift = monitor.handle(KeyEvents.key("a", flags: [.option, .shift]), hotkey: hotkey)
        #expect(exact)
        #expect(!extraShift)
    }
}

@Suite("Output mode resolution")
struct StrategyResolverTests {
    @Test func incompatibleAppsKeepMarkedText() {
        let settings = makeSettings()
        settings.outputMode = .directReplace
        #expect(StrategyResolver.mode(for: "com.apple.Terminal", settings: settings) == .markedText)
        #expect(StrategyResolver.mode(for: "com.microsoft.VSCode", settings: settings) == .directReplace)
        #expect(StrategyResolver.mode(for: "com.apple.TextEdit", settings: settings) == .directReplace)
    }

    @Test func perAppOverrideWins() {
        let settings = makeSettings()
        settings.appOutputModes = ["com.microsoft.VSCode": .directReplace]
        #expect(StrategyResolver.mode(for: "com.microsoft.VSCode", settings: settings) == .directReplace)
    }
}
