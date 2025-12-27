import AppKit
import SwiftUI

public struct RichTextEditor: NSViewRepresentable {
    @Binding public var textView: NSTextView?

    public init(textView: Binding<NSTextView?>) {
        self._textView = textView
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.5
        scrollView.maxMagnification = 3.0

        // Using MultiCursorTextView for multi-selection support
        // To disable: replace with `let textView = NSTextView()`
        let textView = MultiCursorTextView()
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // Dark theme
        textView.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        textView.insertionPointColor = .white
        textView.textColor = .white

        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 12, height: 12)

        scrollView.documentView = textView

        DispatchQueue.main.async {
            self.textView = textView
        }

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
    }

    public func toggleBold() {
        guard let textView, let textStorage = textView.textStorage else { return }
        guard textView.selectedRange.length > 0 else { return }

        let range = textView.selectedRange
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let descriptor = font.fontDescriptor
            let isBold = descriptor.symbolicTraits.contains(.bold)

            var newTraits = descriptor.symbolicTraits
            if isBold {
                newTraits.remove(.bold)
            } else {
                newTraits.insert(.bold)
            }

            let newDescriptor = descriptor.withSymbolicTraits(newTraits)
            let newFont = NSFont(descriptor: newDescriptor, size: font.pointSize) ?? font
            textStorage.addAttribute(.font, value: newFont, range: subRange)
        }
        textStorage.endEditing()
    }

    public func toggleItalic() {
        guard let textView, let textStorage = textView.textStorage else { return }
        guard textView.selectedRange.length > 0 else { return }

        let range = textView.selectedRange
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let descriptor = font.fontDescriptor
            let isItalic = descriptor.symbolicTraits.contains(.italic)

            var newTraits = descriptor.symbolicTraits
            if isItalic {
                newTraits.remove(.italic)
            } else {
                newTraits.insert(.italic)
            }

            let newDescriptor = descriptor.withSymbolicTraits(newTraits)
            let newFont = NSFont(descriptor: newDescriptor, size: font.pointSize) ?? font
            textStorage.addAttribute(.font, value: newFont, range: subRange)
        }
        textStorage.endEditing()
    }

    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        public init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            // Handle text changes if needed
        }
    }
}
