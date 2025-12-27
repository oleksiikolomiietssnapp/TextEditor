import AppKit
import Observation

@Observable @MainActor
public final class TextEditorViewModel {
    public var textView: NSTextView?

    public init() {}

    public func applyBold() {
        guard let textView, let textStorage = textView.textStorage else { return }
        guard textView.selectedRange.length > 0 else { return }

        let range = textView.selectedRange
        let selectedText = textStorage.attributedSubstring(from: range).string
        let styledText = UnicodeStyler.toggleBold(selectedText)

        textStorage.beginEditing()
        textStorage.replaceCharacters(in: range, with: styledText)
        textStorage.endEditing()

        // Restore selection
        textView.setSelectedRange(NSRange(location: range.location, length: styledText.count))
    }

    public func applyItalic() {
        guard let textView, let textStorage = textView.textStorage else { return }
        guard textView.selectedRange.length > 0 else { return }

        let range = textView.selectedRange
        let selectedText = textStorage.attributedSubstring(from: range).string
        let styledText = UnicodeStyler.toggleItalic(selectedText)

        textStorage.beginEditing()
        textStorage.replaceCharacters(in: range, with: styledText)
        textStorage.endEditing()

        // Restore selection
        textView.setSelectedRange(NSRange(location: range.location, length: styledText.count))
    }
}
