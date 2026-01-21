import AppKit
import Combine
import Foundation
import os

struct StorageItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let modifiedDate: Date?
}

enum StorageError: LocalizedError {
    case pathTraversal(String)
    case invalidPath(String)
    case accessDenied(String)

    var errorDescription: String? {
        switch self {
        case .pathTraversal(let message): return "Path Traversal: \(message)"
        case .invalidPath(let message): return "Invalid Path: \(message)"
        case .accessDenied(let message): return "Access Denied: \(message)"
        }
    }
}

enum FileOpenSafety {
    case safe
    case caution
    case dangerous

    static func assess(_ url: URL) -> FileOpenSafety {
        let ext = url.pathExtension.lowercased()

        let safeTypes = [
            "txt", "rtf", "pdf", "jpg", "jpeg", "png", "gif", "bmp", "tiff",
            "mp3", "mp4", "mov", "m4a"
        ]
        if safeTypes.contains(ext) { return .safe }

        let dangerousTypes = [
            "app", "command", "sh", "bash", "zsh", "py", "rb", "pl",
            "pkg", "dmg", "exe", "bat", "cmd"
        ]
        if dangerousTypes.contains(ext) { return .dangerous }

        return .caution
    }
}

final class StorageService: ObservableObject {
    @Published private(set) var items: [StorageItem] = []

    private let storageURL: URL
    private let fileManager: FileManager

    init(storageURL: URL = AppPaths.storageDirectory, fileManager: FileManager = .default) {
        self.storageURL = storageURL
        self.fileManager = fileManager
    }

    func refresh() {
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: storageURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            let mapped = urls.compactMap { url -> StorageItem? in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                return StorageItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: values?.isDirectory ?? false,
                    size: values?.fileSize.map { Int64($0) },
                    modifiedDate: values?.contentModificationDate
                )
            }
            items = mapped.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            AppLogger.storage.error("Failed to list storage directory: \(error.localizedDescription)")
        }
    }

    func open(_ item: StorageItem) {
        do {
            try validatePath(item.url)
            if item.isDirectory {
                NSWorkspace.shared.open(item.url)
                StorageAuditLog.log(operation: "OPEN_DIR", file: item.url, success: true)
                return
            }

            var didOpen = false
            switch FileOpenSafety.assess(item.url) {
            case .safe:
                NSWorkspace.shared.open(item.url)
                didOpen = true

            case .caution:
                let alert = NSAlert()
                alert.messageText = "Open this file?"
                alert.informativeText = "'\(item.name)' may contain active content."
                alert.addButton(withTitle: "Open")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .warning

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(item.url)
                    didOpen = true
                }

            case .dangerous:
                let alert = NSAlert()
                alert.messageText = "Security Warning"
                alert.informativeText = "'\(item.name)' is an executable file that could harm your Mac. Only open this if you trust its source."
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Open Anyway")
                alert.alertStyle = .critical

                if alert.runModal() == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(item.url)
                    didOpen = true
                }
            }

            StorageAuditLog.log(operation: "OPEN", file: item.url, success: didOpen)
        } catch {
            StorageAuditLog.log(operation: "OPEN", file: item.url, success: false)
            showError(error)
        }
    }

    func reveal(_ item: StorageItem) {
        do {
            try validatePath(item.url)
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
            StorageAuditLog.log(operation: "REVEAL", file: item.url, success: true)
        } catch {
            StorageAuditLog.log(operation: "REVEAL", file: item.url, success: false)
            showError(error)
        }
    }

    func delete(_ item: StorageItem) {
        do {
            try validatePath(item.url)
            let alert = NSAlert()
            alert.messageText = "Delete '\(item.name)'?"
            alert.informativeText = "This action cannot be undone."
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning

            guard alert.runModal() == .alertFirstButtonReturn else { return }

            try fileManager.removeItem(at: item.url)
            StorageAuditLog.log(operation: "DELETE", file: item.url, success: true)
            refresh()
        } catch {
            StorageAuditLog.log(operation: "DELETE", file: item.url, success: false)
            showError(error)
        }
    }

    func createFolder(named name: String) {
        let sanitized = sanitizeFileName(name)
        guard !sanitized.isEmpty else {
            showError(StorageError.invalidPath("Folder name is empty."))
            return
        }

        let folderURL = storageURL.appendingPathComponent(sanitized, isDirectory: true)
        do {
            try validatePath(folderURL)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false)
            StorageAuditLog.log(operation: "CREATE_FOLDER", file: folderURL, success: true)
            refresh()
        } catch {
            StorageAuditLog.log(operation: "CREATE_FOLDER", file: folderURL, success: false)
            showError(error)
        }
    }

    func sanitizeFileName(_ name: String) -> String {
        var sanitized = name.replacingOccurrences(of: "/", with: "-")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        while sanitized.hasPrefix(".") {
            sanitized.removeFirst()
        }

        if sanitized.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let base = (sanitized as NSString).deletingPathExtension
            sanitized = String(base.prefix(250)) + "." + ext
        }

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validatePath(_ url: URL) throws {
        let canonicalURL = url.resolvingSymlinksInPath().standardizedFileURL
        let canonicalStorage = storageURL.resolvingSymlinksInPath().standardizedFileURL

        let storagePath = canonicalStorage.path
        if canonicalURL.path != storagePath && !canonicalURL.path.hasPrefix(storagePath + "/") {
            throw StorageError.pathTraversal("File is outside storage directory")
        }

        let components = canonicalURL.pathComponents
        if components.contains("..") || components.contains(".") {
            throw StorageError.invalidPath("Path contains invalid components")
        }
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Storage Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
