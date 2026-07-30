import AppKit
import Foundation
import UniformTypeIdentifiers

enum DropValidationError: LocalizedError {
    case pathTraversal
    case symlinkDetected
    case fileTooLarge
    case invalidName
    case forbiddenType
    case outsideStorage
    case unreadable

    var errorDescription: String? {
        switch self {
        case .pathTraversal: return "File path contains invalid traversal"
        case .symlinkDetected: return "Symbolic links are not allowed"
        case .fileTooLarge: return "File exceeds maximum size limit"
        case .invalidName: return "File name contains invalid characters"
        case .forbiddenType: return "File type is not allowed"
        case .outsideStorage: return "Target path is outside storage directory"
        case .unreadable: return "File is not readable"
        }
    }
}

enum DropValidator {
    static let maxFileSize: Int64 = 100 * 1024 * 1024
    static let forbiddenExtensions = [
        "command", "terminal", "workflow", "scpt", "scptd", "applescript", "action"
    ]

    static func validateDroppedFile(_ url: URL, storageURL: URL) throws -> URL {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else {
            throw DropValidationError.invalidName
        }

        guard fileManager.isReadableFile(atPath: url.path) else {
            throw DropValidationError.unreadable
        }

        // Reject only when the dropped item *itself* is a symlink. The previous
        // check compared the fully resolved path against the original, which
        // also fired for any file living under a symlinked ancestor (/tmp ->
        // /private/tmp, /var, many /Volumes mounts), falsely rejecting valid
        // drops from those locations.
        let symlinkValues = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if symlinkValues?.isSymbolicLink == true {
            throw DropValidationError.symlinkDetected
        }

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64,
           fileSize > maxFileSize {
            throw DropValidationError.fileTooLarge
        }

        try validateFileType(url)

        let sanitizedName = sanitizeFileName(url.lastPathComponent)
        guard !sanitizedName.isEmpty else {
            throw DropValidationError.invalidName
        }

        let targetURL = storageURL.appendingPathComponent(sanitizedName)
        switch PathSecurity.containmentViolation(for: targetURL, within: storageURL) {
        case .outside:
            throw DropValidationError.outsideStorage
        case .invalidComponents:
            throw DropValidationError.pathTraversal
        case nil:
            break
        }

        return targetURL
    }

    static func validateFileType(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        if forbiddenExtensions.contains(ext) {
            throw DropValidationError.forbiddenType
        }
        if ext == "app" {
            StorageAuditLog.log(operation: "DROP_APP_BUNDLE", file: url, success: true)
        }
    }

    static func sanitizeFileName(_ name: String) -> String {
        PathSecurity.sanitizeFileName(name)
    }
}

struct DropResult {
    let succeeded: [String]
    let failed: [(String, Error)]

    var successCount: Int { succeeded.count }
    var failureCount: Int { failed.count }

    var message: String {
        if failureCount == 0 {
            return succeeded.count == 1 ? "Added '\(succeeded[0])'" : "Added \(succeeded.count) files"
        } else if successCount == 0 {
            return "Failed to add \(failureCount) file(s)"
        } else {
            return "Added \(successCount), failed \(failureCount)"
        }
    }
}

final class DropHandler {
    private let storageURL: URL

    init(storageURL: URL = AppPaths.storageDirectory) {
        self.storageURL = storageURL
    }

    /// Extract file URLs from drag-and-drop item providers. Shared by the mascot
    /// and storage-browser drop targets so the extraction logic lives in one place.
    static func loadFileURLs(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        let identifier = UTType.fileURL.identifier

        for provider in providers where provider.hasItemConformingToTypeIdentifier(identifier) {
            guard let item = try? await provider.loadItem(forTypeIdentifier: identifier) else { continue }
            if let url = item as? URL {
                urls.append(url)
            } else if let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) {
                urls.append(url)
            }
        }

        return urls
    }

    func handleDrop(urls: [URL], window: NSWindow?) async -> DropResult {
        var succeeded: [String] = []
        var failed: [(String, Error)] = []

        for url in urls {
            do {
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let targetURL = try DropValidator.validateDroppedFile(url, storageURL: storageURL)
                let finalURL = try resolveCollision(targetURL)
                try FileManager.default.copyItem(at: url, to: finalURL)
                succeeded.append(finalURL.lastPathComponent)
                StorageAuditLog.log(operation: "DROP", file: finalURL, success: true)
            } catch {
                failed.append((url.lastPathComponent, error))
                StorageAuditLog.log(operation: "DROP_FAILED", file: url, success: false)
            }
        }

        let result = DropResult(succeeded: succeeded, failed: failed)
        await MainActor.run {
            DropFeedbackController.showDropResult(result, in: window)
        }

        return result
    }

    private func resolveCollision(_ url: URL) throws -> URL {
        let fileManager = FileManager.default
        var candidateURL = url
        var counter = 1

        while fileManager.fileExists(atPath: candidateURL.path) {
            let baseName = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let newName = ext.isEmpty ? "\(baseName) (\(counter))" : "\(baseName) (\(counter)).\(ext)"
            candidateURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
            if counter > 1000 {
                throw DropValidationError.invalidName
            }
        }

        return candidateURL
    }
}

enum DropFeedbackController {
    static func showDropResult(_ result: DropResult, in window: NSWindow?) {
        if result.failureCount > 0 {
            let alert = NSAlert()
            alert.messageText = "Some files could not be added"
            let failureList = result.failed
                .map { "- \($0.0): \($0.1.localizedDescription)" }
                .joined(separator: "\n")
            alert.informativeText = "Successfully added: \(result.successCount)\nFailed: \(result.failureCount)\n\nErrors:\n\(failureList)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")

            if let window = window {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        } else {
            BlurbController.shared.show(message: result.message, icon: .success, duration: 2.0)
        }
    }
}
