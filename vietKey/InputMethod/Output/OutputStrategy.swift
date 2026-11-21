import InputMethodKit
import VietEngine

protocol OutputStrategy: AnyObject {
    func isInSync(with client: any IMKTextInput) -> Bool
    func apply(_ output: EngineOutput, to client: any IMKTextInput)
    func commit(_ text: String, to client: any IMKTextInput)
    /// Whether the app's own backspace gives `output`; the strategy then expects it instead of writing.
    func letsAppDelete(_ output: EngineOutput) -> Bool
}

extension NSRange {
    nonisolated static let notFound = NSRange(location: NSNotFound, length: NSNotFound)
}
