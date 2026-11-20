@testable import VietEngine

/// ⌫ stands for Backspace.
enum TypingSimulator {
    static let mechanics = EngineOptions(spellCheck: false)

    static func type(_ input: String, options: EngineOptions = EngineOptions()) -> String {
        var engine = VietEngine(options: options)
        var text = ""
        for character in input {
            let isBackspace = character == "⌫"
            let output = engine.process(isBackspace ? .backspace : .character(character))
            text += output.commitText
            if !output.consumed {
                if isBackspace {
                    if !text.isEmpty { text.removeLast() }
                } else {
                    text.append(character)
                }
            }
        }
        return text + engine.commit()
    }

    static func typeDirect(_ input: String, options: EngineOptions = EngineOptions()) -> String {
        var engine = VietEngine(options: options)
        var units: [UInt16] = []
        for character in input + " " {
            let isBackspace = character == "⌫"
            let output = engine.process(isBackspace ? .backspace : .character(character))
            units.removeLast(output.deleteCount)
            units += Array(output.insertText.utf16)
            guard !output.consumed else { continue }
            if isBackspace {
                var text = String(decoding: units, as: UTF16.self)
                if !text.isEmpty { text.removeLast() }
                units = Array(text.utf16)
            } else {
                units += Array(String(character).utf16)
            }
        }
        return String(String(decoding: units, as: UTF16.self).dropLast())
    }
}
