# TextEditor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

A modern macOS text editor with Unicode-based text styling. Apply bold and italic formatting that remains portable across all platforms.

## Overview

TextEditor is a minimalist rich-text editor built with SwiftUI and AppKit that uses Unicode mathematical alphanumeric symbols for text styling. Unlike traditional font-based formatting, styled text remains formatted when copied to plain text environments (Twitter, Slack, Mastodon, etc.).

### Example

```
Normal:      Hello World
Bold:        𝗛𝗲𝗹𝗹𝗼 𝗪𝗼𝗿𝗹𝗱
Italic:      𝘏𝘦𝘭𝘭𝘰 𝘞𝘰𝘳𝘭𝘥
Bold+Italic: 𝙃𝙚𝙡𝙡𝙤 𝙒𝙤𝙧𝙡𝙙
```

## Key Features

- **Unicode-Based Styling** - Mathematical sans-serif symbols (U+1D5D4–U+1D66F) for portable formatting
- **File Browser Sidebar** - Navigate folders with support for `.txt`, `.rtf`, `.rtfd`, `.md` files
- **Session Persistence** - Security-scoped bookmarks remember your workspace between launches
- **Native Experience** - Full undo/redo, keyboard shortcuts (⌘B, ⌘I, ⌘S, ⌘O)
- **Dark Theme** - Minimalist dark interface optimized for writing

## Architecture

The project is split into two components:

```
TextEditor/          # Main macOS app (SwiftUI + AppKit)
└── TextEditorKit/   # Reusable Swift Package
    ├── RichTextEditor        # NSTextView wrapper
    ├── UnicodeStyler         # Unicode character mapping engine
    └── TextEditorViewModel   # State coordination
```

### Technical Highlights

- **Swift 6.0** with strict concurrency checking
- **SwiftUI + AppKit hybrid** - Modern UI with native text editing
- **Observable pattern** - Reactive state management with `@Observable`
- **Security-scoped bookmarks** - Proper sandboxed folder access
- **Recursive file tree** - Hierarchical folder navigation

## How It Works

The `UnicodeStyler` engine:
1. Detects current character style by analyzing Unicode scalar values
2. Maps characters to/from mathematical alphanumeric symbol ranges
3. Toggles styles intelligently (e.g., adding bold to italic text creates bold-italic)
4. Preserves styles when copying to any plain text system

## Requirements

- macOS 15.0+ (Sequoia)
- Swift 6.0+
- Xcode 16.0+

## Building

```bash
cd TextEditor
xcodebuild -project TextEditor.xcodeproj -scheme TextEditor build
```

Or open `TextEditor.xcodeproj` in Xcode and press ⌘R.

## Usage

1. **Select Folder** - Click the sidebar button to choose a working directory
2. **Edit Files** - Click any file in the sidebar to open it
3. **Apply Styles** - Select text and press ⌘B (bold) or ⌘I (italic)
4. **Save** - Press ⌘S to save (creates `.txt` file)

Styled text copied from the editor will maintain formatting in any app that supports Unicode.

## Why Unicode Styling?

Traditional rich text formatting uses font attributes (NSFont, NSAttributedString) that only work within RTF-aware applications. Unicode styling uses actual Unicode characters, making styled text portable:

- ✅ Works in social media (Twitter, Mastodon, Bluesky)
- ✅ Works in messaging apps (Slack, Discord, iMessage)
- ✅ Works in plain text files
- ✅ Works in code comments
- ✅ No special rendering required

## License

MIT License - see [LICENSE](LICENSE) for details.
