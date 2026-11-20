public struct MacroTable: Sendable, Equatable {
    public private(set) var entries: [String: String]

    public init(_ entries: [String: String] = [:]) {
        self.entries = entries
    }

    public func expansion(for word: String) -> String? {
        guard !word.isEmpty else { return nil }
        if let exact = entries[word] { return exact }

        guard let expansion = entries[word.lowercased()] else { return nil }
        if word.count > 1 && word == word.uppercased() {
            return expansion.uppercased()
        }
        if word.first?.isUppercase == true {
            return expansion.prefix(1).uppercased() + expansion.dropFirst()
        }
        return nil
    }
}
