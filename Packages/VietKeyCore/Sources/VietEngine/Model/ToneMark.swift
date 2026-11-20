public enum ToneMark: Int, Sendable, CaseIterable {
    case none = 0
    case acute   // sắc
    case grave   // huyền
    case hook    // hỏi
    case tilde   // ngã
    case dot     // nặng
}

public enum LetterMod: Sendable {
    case none
    case circumflex  // â ê ô
    case breve       // ă
    case horn        // ơ ư
    case stroke      // đ
}
