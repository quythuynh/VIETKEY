public enum MacroFileFormat {
    static let header = ";DO NOT DELETE THIS LINE*** version=1 ***"

    public static func parse(_ text: String) -> [String: String] {
        var entries: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            guard !line.hasPrefix(";"), let colon = line.firstIndex(of: ":") else { continue }
            let key = trimmed(line[..<colon])
            let value = trimmed(line[line.index(after: colon)...])
            if !key.isEmpty && !value.isEmpty {
                entries[key] = value
            }
        }
        return entries
    }

    public static func serialize(_ entries: [String: String]) -> String {
        let lines = entries.keys.sorted().map { "\($0):\(entries[$0] ?? "")" }
        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    private static func trimmed(_ text: Substring) -> String {
        String(text.drop(while: \.isWhitespace).reversed().drop(while: \.isWhitespace).reversed())
    }
}
