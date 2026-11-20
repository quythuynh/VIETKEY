public struct EngineOutput: Sendable, Equatable {
    public var consumed: Bool
    public var commitText: String
    public var composing: String
    public var deleteCount: Int
    public var insertText: String

    public init(consumed: Bool, commitText: String = "", composing: String = "", deleteCount: Int = 0, insertText: String = "") {
        self.consumed = consumed
        self.commitText = commitText
        self.composing = composing
        self.deleteCount = deleteCount
        self.insertText = insertText
    }

    public static let passThrough = EngineOutput(consumed: false)
}
