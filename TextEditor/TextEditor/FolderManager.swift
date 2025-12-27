import Foundation
import AppKit
import Observation

@Observable @MainActor
final class FolderManager {
    private let bookmarkKey = "lastFolderBookmark"
    private let allowedExtensions = ["txt", "rtf", "rtfd", "md"]

    var fileTree: [FileItem] = []
    var currentFolderURL: URL?
    private var securityScopedURL: URL?

    init() {
        loadLastFolder()
    }

    // MARK: - Folder Selection

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            loadFolder(url)
            saveBookmark(for: url)
        }
    }

    // MARK: - Folder Loading

    func loadFolder(_ url: URL) {
        stopAccessingSecurityScopedResource()
        currentFolderURL = url
        securityScopedURL = url
        _ = url.startAccessingSecurityScopedResource()
        fileTree = buildFileTree(for: url)
    }

    private func loadLastFolder() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Bookmark is stale, re-create it
                saveBookmark(for: url)
            }

            loadFolder(url)
        } catch {
            print("Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    // MARK: - Bookmark Persistence

    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    private func stopAccessingSecurityScopedResource() {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = nil
    }

    // MARK: - File Tree Building

    private func buildFileTree(for url: URL) -> [FileItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { itemURL -> FileItem? in
            let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues?.isDirectory ?? false

            if isDirectory {
                // Recursively build children
                let children = buildFileTree(for: itemURL)
                // Only include directory if it has children
                guard !children.isEmpty else { return nil }

                return FileItem(
                    url: itemURL,
                    name: itemURL.lastPathComponent,
                    isDirectory: true,
                    children: children
                )
            } else if allowedExtensions.contains(itemURL.pathExtension.lowercased()) {
                return FileItem(
                    url: itemURL,
                    name: itemURL.lastPathComponent,
                    isDirectory: false,
                    children: nil
                )
            }

            return nil
        }.sorted { item1, item2 in
            // Folders first, then alphabetically
            if item1.isDirectory != item2.isDirectory {
                return item1.isDirectory
            }
            return item1.name.localizedStandardCompare(item2.name) == .orderedAscending
        }
    }
}
