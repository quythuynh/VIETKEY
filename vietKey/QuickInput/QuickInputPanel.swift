import AppKit

/// Floating window with the quick input text view and a hint line.
final class QuickInputPanel: NSPanel {
    let textView = QuickInputTextView()
    private let hintLabel = NSTextField(labelWithString: "")

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 560, height: 170),
                   styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        title = String(localized: "VIET Quick Input")
        level = .floating
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        contentView = makeContent()
        placeInUpperMiddle()
    }

    var hint: String {
        get { hintLabel.stringValue }
        set { hintLabel.stringValue = newValue }
    }

    func present() {
        makeKeyAndOrderFront(nil)
        makeFirstResponder(textView)
    }

    private func makeContent() -> NSView {
        textView.font = .systemFont(ofSize: 16)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.lineBreakMode = .byTruncatingTail

        let stack = NSStackView(views: [scrollView, hintLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 10, right: 12)
        scrollView.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24).isActive = true
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        return stack
    }

    private func placeInUpperMiddle() {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        setFrameOrigin(NSPoint(x: screen.midX - frame.width / 2, y: screen.maxY - screen.height / 3))
    }
}
