import Foundation
import VietEngine
import VietCharset

extension InputMethodKind {
    var displayName: String {
        switch self {
        case .telex: String(localized: "Telex")
        case .telexExtended: String(localized: "Telex Extended ([ → ơ, ] → ư)")
        case .vni: String(localized: "VNI")
        case .viqr: String(localized: "VIQR")
        }
    }
}

extension ToneStyle {
    var displayName: String {
        switch self {
        case .new: String(localized: "Modern (hoà, thuỷ)")
        case .old: String(localized: "Traditional (hòa, thủy)")
        }
    }
}

extension OutputMode {
    var displayName: String {
        switch self {
        case .markedText: String(localized: "Underlined while typing (most compatible)")
        case .directReplace: String(localized: "Replace directly (no underline)")
        }
    }
}

extension Charset {
    var displayName: String {
        switch self {
        case .unicode: String(localized: "Unicode")
        case .unicodeComposite: String(localized: "Unicode Composite (NFD)")
        case .tcvn3: String(localized: "TCVN3 (ABC)")
        case .vniWindows: String(localized: "VNI-Windows")
        case .viqr: String(localized: "VIQR")
        }
    }
}
