public enum ToneStyle: String, Sendable, CaseIterable {
    case old
    case new
}

public enum InputMethodKind: String, Sendable, CaseIterable {
    case telex
    case telexExtended
    case vni
    case viqr

    var method: any InputMethod {
        switch self {
        case .telex: Telex(extended: false)
        case .telexExtended: Telex(extended: true)
        case .vni: VNI()
        case .viqr: VIQR()
        }
    }
}

public struct EngineOptions: Sendable, Equatable {
    public var inputMethod: InputMethodKind
    public var toneStyle: ToneStyle
    public var spellCheck: Bool
    public var macros: MacroTable

    public init(
        inputMethod: InputMethodKind = .telex,
        toneStyle: ToneStyle = .new,
        spellCheck: Bool = true,
        macros: MacroTable = MacroTable()
    ) {
        self.inputMethod = inputMethod
        self.toneStyle = toneStyle
        self.spellCheck = spellCheck
        self.macros = macros
    }
}
