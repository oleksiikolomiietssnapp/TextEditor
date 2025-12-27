import SwiftUI
import AppKit
import UniformTypeIdentifiers
import TextEditorKit

struct ContentView: View {
    @State private var textView: NSTextView?
    @State private var viewModel = TextEditorViewModel()
    @State private var currentFileURL: URL?
    @State private var folderManager = FolderManager()
    @State private var zoomLevel: CGFloat = 1.0

    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 3.0
    private let zoomStep: CGFloat = 0.1

    var body: some View {
        NavigationSplitView {
            SidebarView(folderManager: folderManager, onFileSelect: loadFile)
        } detail: {
            EditorView(
                textView: $textView,
                viewModel: viewModel,
                zoomLevel: zoomLevel
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    openFile()
                } label: {
                    Label("Open", systemImage: "doc")
                }
                .keyboardShortcut("o", modifiers: .command)
                .help("Open File (⌘O)")

                Button {
                    saveFile()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .help("Save File (⌘S)")

                Divider()

                Button {
                    zoomOut()
                } label: {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)
                .help("Zoom Out (⌘-)")
                .disabled(zoomLevel <= minZoom)

                Text("\(Int(zoomLevel * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 40)

                Button {
                    zoomIn()
                } label: {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("=", modifiers: .command)
                .help("Zoom In (⌘+)")
                .disabled(zoomLevel >= maxZoom)
            }
        }
        .onChange(of: zoomLevel) { _, newValue in
            applyZoom(newValue)
        }
    }

    // MARK: - Zoom

    private func zoomIn() {
        zoomLevel = min(zoomLevel + zoomStep, maxZoom)
    }

    private func zoomOut() {
        zoomLevel = max(zoomLevel - zoomStep, minZoom)
    }

    private func applyZoom(_ zoom: CGFloat) {
        guard let textView else { return }

        // Get the enclosing scroll view
        if let scrollView = textView.enclosingScrollView {
            scrollView.magnification = zoom
        }
    }

    // MARK: - File Operations

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.rtf, .plainText, .rtfd]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            loadFile(from: url)
        }
    }

    private func loadFile(from url: URL) {
        guard let textView else { return }

        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: url.pathExtension == "rtf" || url.pathExtension == "rtfd"
                    ? NSAttributedString.DocumentType.rtf
                    : NSAttributedString.DocumentType.plain
            ]
            let attributedString = try NSAttributedString(url: url, options: options, documentAttributes: nil)

            textView.textStorage?.setAttributedString(attributedString)
            textView.textStorage?.addAttribute(
                .foregroundColor,
                value: NSColor.white,
                range: NSRange(location: 0, length: textView.textStorage?.length ?? 0)
            )

            currentFileURL = url
        } catch {
            print("Failed to load file: \(error)")
        }
    }

    private func saveFile() {
        guard let textView, let textStorage = textView.textStorage else { return }

        if let url = currentFileURL {
            saveToURL(url, textStorage: textStorage)
        } else {
            saveAsNewFile(textStorage: textStorage)
        }
    }

    private func saveAsNewFile(textStorage: NSTextStorage) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "Untitled.txt"

        if panel.runModal() == .OK, let url = panel.url {
            saveToURL(url, textStorage: textStorage)
            currentFileURL = url
        }
    }

    private func saveToURL(_ url: URL, textStorage: NSTextStorage) {
        do {
            let plainText = textStorage.string
            try plainText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Bindable var folderManager: FolderManager
    let onFileSelect: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let folderURL = folderManager.currentFolderURL {
                    Label(folderURL.lastPathComponent, systemImage: "folder.fill")
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text("No Folder")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    folderManager.selectFolder()
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.borderless)
                .help("Change Folder")
            }
            .padding()

            Divider()

            if folderManager.fileTree.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No folder selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("Select Folder") {
                        folderManager.selectFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(folderManager.fileTree, id: \.id, children: \.children) { item in
                    FileItemRow(item: item) {
                        if !item.isDirectory {
                            onFileSelect(item.url)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

// MARK: - Editor View

struct EditorView: View {
    @Binding var textView: NSTextView?
    var viewModel: TextEditorViewModel
    var zoomLevel: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            RichTextEditor(textView: $textView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: textView) { _, newValue in
                    viewModel.textView = newValue
                }

            Divider()

            // Bottom toolbar - Bold/Italic controls
            HStack(spacing: 12) {
                Button {
                    viewModel.applyBold()
                } label: {
                    Text("B")
                        .font(.title3)
                        .bold()
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("b", modifiers: .command)
                .help("Bold (⌘B)")

                Button {
                    viewModel.applyItalic()
                } label: {
                    Text("I")
                        .font(.title3)
                        .italic()
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("i", modifiers: .command)
                .help("Italic (⌘I)")

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)))
    }
}

// MARK: - File Item Row

struct FileItemRow: View {
    let item: FileItem
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            Label {
                Text(item.name)
            } icon: {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                    .foregroundStyle(item.isDirectory ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
