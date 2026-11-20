public enum OutputDiff {
    /// deleteCount is in UTF-16 units, like the host's NSRange.
    public static func between(_ old: String, _ new: String) -> (deleteCount: Int, insert: String) {
        var oldIndex = old.startIndex
        var newIndex = new.startIndex
        while oldIndex < old.endIndex, newIndex < new.endIndex, old[oldIndex] == new[newIndex] {
            old.formIndex(after: &oldIndex)
            new.formIndex(after: &newIndex)
        }
        return (old[oldIndex...].utf16.count, String(new[newIndex...]))
    }
}
