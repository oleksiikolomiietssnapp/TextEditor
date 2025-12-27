import AppKit

/// Custom NSTextView subclass that supports multiple cursors/selections.
/// This is an experimental feature - can be removed by deleting this file
/// and reverting RichTextEditor to use standard NSTextView.
///
/// Usage:
/// - Ctrl+Click to add a cursor at that position
/// - Ctrl+Shift+Click to add a selection
/// - Escape to clear extra cursors (keep only primary)
/// - Typing affects all cursor positions
public class MultiCursorTextView: NSTextView {

    // MARK: - Additional Selections

    /// Additional selection ranges beyond the primary selectedRange
    private var additionalSelections: [NSRange] = []

    /// Color for additional selection highlights
    private var additionalSelectionColor: NSColor {
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.5)
    }

    /// Color for additional cursors
    private var additionalCursorColor: NSColor {
        insertionPointColor
    }

    // MARK: - Properties

    /// All selections including primary and additional
    public var allSelections: [NSRange] {
        var selections = [selectedRange]
        selections.append(contentsOf: additionalSelections)
        return selections.sorted { $0.location < $1.location }
    }

    /// Whether multi-cursor mode is active
    public var hasMultipleCursors: Bool {
        !additionalSelections.isEmpty
    }

    // MARK: - Mouse Handling

    public override func mouseDown(with event: NSEvent) {
        // Ctrl+Click adds a new cursor
        if event.modifierFlags.contains(.control) {
            let point = convert(event.locationInWindow, from: nil)
            let index = characterIndexForInsertion(at: point)

            if event.modifierFlags.contains(.shift) {
                // Ctrl+Shift+Click: Add selection from last cursor to this point
                let lastLocation = additionalSelections.last?.location ?? selectedRange.location
                let start = min(lastLocation, index)
                let end = max(lastLocation, index)
                let range = NSRange(location: start, length: end - start)
                addSelection(range)
            } else {
                // Ctrl+Click: Add cursor at point
                addSelection(NSRange(location: index, length: 0))
            }
            return
        }

        // Regular click clears additional selections
        clearAdditionalSelections()
        super.mouseDown(with: event)
    }

    // MARK: - Keyboard Handling

    public override func keyDown(with event: NSEvent) {
        // Escape clears additional cursors
        if event.keyCode == 53 { // Escape
            if hasMultipleCursors {
                clearAdditionalSelections()
                return
            }
        }

        super.keyDown(with: event)
    }

    public override func insertText(_ string: Any, replacementRange: NSRange) {
        guard hasMultipleCursors, let text = string as? String else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        // Insert at all cursor positions (in reverse order to preserve indices)
        let allRanges = allSelections.sorted { $0.location > $1.location }

        textStorage?.beginEditing()

        for range in allRanges {
            if let textStorage = textStorage {
                textStorage.replaceCharacters(in: range, with: text)
            }
        }

        textStorage?.endEditing()

        // Update cursor positions
        updateCursorsAfterInsertion(text: text, originalRanges: allRanges)
    }

    public override func deleteBackward(_ sender: Any?) {
        guard hasMultipleCursors else {
            super.deleteBackward(sender)
            return
        }

        // Delete at all cursor positions (in reverse order)
        let allRanges = allSelections.sorted { $0.location > $1.location }

        textStorage?.beginEditing()

        for range in allRanges {
            if range.length > 0 {
                // Delete selection
                textStorage?.replaceCharacters(in: range, with: "")
            } else if range.location > 0 {
                // Delete character before cursor
                let deleteRange = NSRange(location: range.location - 1, length: 1)
                textStorage?.replaceCharacters(in: deleteRange, with: "")
            }
        }

        textStorage?.endEditing()

        // Update cursor positions after deletion
        updateCursorsAfterDeletion(originalRanges: allRanges)
    }

    // MARK: - Selection Management

    private func addSelection(_ range: NSRange) {
        // Don't add duplicate selections
        guard !additionalSelections.contains(range),
              range != selectedRange else {
            return
        }

        additionalSelections.append(range)
        setNeedsDisplay(bounds)
    }

    private func clearAdditionalSelections() {
        additionalSelections.removeAll()
        setNeedsDisplay(bounds)
    }

    private func updateCursorsAfterInsertion(text: String, originalRanges: [NSRange]) {
        let insertLength = text.utf16.count
        var newAdditional: [NSRange] = []
        var offset = 0

        // Process in forward order for offset calculation
        let forwardRanges = originalRanges.reversed()

        for (index, range) in forwardRanges.enumerated() {
            let deletedLength = range.length
            let newLocation = range.location - offset + insertLength

            if index == 0 {
                // Primary selection
                setSelectedRange(NSRange(location: newLocation, length: 0))
            } else {
                newAdditional.append(NSRange(location: newLocation, length: 0))
            }

            offset += deletedLength - insertLength
        }

        additionalSelections = newAdditional
        setNeedsDisplay(bounds)
    }

    private func updateCursorsAfterDeletion(originalRanges: [NSRange]) {
        var newAdditional: [NSRange] = []
        var totalOffset = 0

        let forwardRanges = originalRanges.reversed()

        for (index, range) in forwardRanges.enumerated() {
            let deletedLength = range.length > 0 ? range.length : 1
            let newLocation = max(0, range.location - totalOffset - (range.length > 0 ? 0 : 1))

            if index == 0 {
                setSelectedRange(NSRange(location: newLocation, length: 0))
            } else {
                newAdditional.append(NSRange(location: newLocation, length: 0))
            }

            totalOffset += deletedLength
        }

        additionalSelections = newAdditional
        setNeedsDisplay(bounds)
    }

    // MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw additional selections/cursors
        guard hasMultipleCursors, let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return
        }

        for range in additionalSelections {
            if range.length > 0 {
                // Draw selection highlight
                drawSelectionHighlight(for: range, layoutManager: layoutManager, textContainer: textContainer)
            } else {
                // Draw cursor
                drawCursor(at: range.location, layoutManager: layoutManager, textContainer: textContainer)
            }
        }
    }

    private func drawSelectionHighlight(for range: NSRange, layoutManager: NSLayoutManager, textContainer: NSTextContainer) {
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        rect.origin.x += textContainerOrigin.x
        rect.origin.y += textContainerOrigin.y

        additionalSelectionColor.setFill()
        rect.fill()
    }

    private func drawCursor(at location: Int, layoutManager: NSLayoutManager, textContainer: NSTextContainer) {
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: min(location, (textStorage?.length ?? 1) - 1))
        var rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)

        rect.origin.x += textContainerOrigin.x
        rect.origin.y += textContainerOrigin.y
        rect.size.width = 2 // Cursor width

        additionalCursorColor.setFill()
        rect.fill()
    }

}
