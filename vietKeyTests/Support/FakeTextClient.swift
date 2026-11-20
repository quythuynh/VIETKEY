import AppKit
import Carbon
import InputMethodKit
@testable import vietKey
import VietEngine

/// A text field as IMK sees it: committed text, a caret and marked text.
nonisolated final class FakeTextClient: NSObject, IMKTextInput {
    var text = ""
    var caret = 0
    var marked = ""
    var ignoresMarkedText = false
    var reportsCaret = true
    private(set) var caretQueries = 0
    private(set) var clientIDQueries = 0
    private(set) var markedRangeQueries = 0
    /// Caret reported instead of the real one, like a chat app right after clearing its input.
    var staleCaret: Int?
    let bundleID: String
    let clientID: String

    init(bundleID: String = "test.app", clientID: String = UUID().uuidString) {
        self.bundleID = bundleID
        self.clientID = clientID
    }

    var screen: String { text + marked }

    /// What the app does with a key the input method didn't consume.
    func receiveUnhandledKey(_ character: Character) {
        if character == "⌫" {
            guard caret > 0 else { return }
            let range = (text as NSString).rangeOfComposedCharacterSequence(at: caret - 1)
            text = (text as NSString).replacingCharacters(in: range, with: "")
            caret = range.location
        } else {
            insertText(String(character), replacementRange: .notFound)
        }
    }

    func insertText(_ string: Any!, replacementRange: NSRange) {
        let inserted = string as? String ?? ""
        let range = replacementRange.location == NSNotFound ? NSRange(location: caret, length: 0) : replacementRange
        // Real apps ignore ranges outside their text.
        guard NSMaxRange(range) <= (text as NSString).length else { return }
        staleCaret = nil
        text = (text as NSString).replacingCharacters(in: range, with: inserted)
        caret = range.location + (inserted as NSString).length
        marked = ""
    }

    func setMarkedText(_ string: Any!, selectionRange: NSRange, replacementRange: NSRange) {
        if !ignoresMarkedText {
            marked = string as? String ?? ""
        }
    }

    func selectedRange() -> NSRange {
        caretQueries += 1
        return NSRange(location: reportsCaret ? (staleCaret ?? caret) : NSNotFound, length: 0)
    }
    func markedRange() -> NSRange {
        markedRangeQueries += 1
        return currentMarkedRange
    }

    private var currentMarkedRange: NSRange {
        marked.isEmpty ? NSRange(location: NSNotFound, length: 0) : NSRange(location: caret, length: (marked as NSString).length)
    }
    func bundleIdentifier() -> String! { bundleID }
    func uniqueClientIdentifierString() -> String! {
        clientIDQueries += 1
        return clientID
    }

    func attributedSubstring(from range: NSRange) -> NSAttributedString! { nil }
    func length() -> Int { (text as NSString).length }
    func characterIndex(for point: NSPoint, tracking mappingMode: IMKLocationToOffsetMappingMode, inMarkedRange: UnsafeMutablePointer<ObjCBool>!) -> Int { 0 }
    func attributes(forCharacterIndex index: Int, lineHeightRectangle lineRect: UnsafeMutablePointer<NSRect>!) -> [AnyHashable: Any]! { [:] }
    func validAttributesForMarkedText() -> [Any]! { [] }
    func overrideKeyboard(withKeyboardNamed keyboardUniqueName: String!) {}
    func selectMode(_ modeIdentifier: String!) {}
    func supportsUnicode() -> Bool { true }
    func windowLevel() -> CGWindowLevel { 0 }
    func supportsProperty(_ property: TSMDocumentPropertyTag) -> Bool { false }
    func string(from range: NSRange, actualRange: NSRangePointer!) -> String! {
        // Like IMK, write through the pointer unconditionally: passing nil crashes.
        actualRange.pointee = range
        guard NSMaxRange(range) <= (text as NSString).length else { return nil }
        return (text as NSString).substring(with: range)
    }
    func firstRect(forCharacterRange aRange: NSRange, actualRange: NSRangePointer!) -> NSRect { .zero }
}
