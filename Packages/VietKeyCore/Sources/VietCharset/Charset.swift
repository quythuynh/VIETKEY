public enum Charset: String, Sendable, CaseIterable, Identifiable {
    case unicode
    case unicodeComposite
    case tcvn3
    case vniWindows
    case viqr

    public var id: String { rawValue }
}
