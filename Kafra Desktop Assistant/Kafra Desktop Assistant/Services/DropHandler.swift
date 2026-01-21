import AppKit
import Foundation

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

        let resolvedURL = url.resolvingSymlinksInPath()
        if resolvedURL != url {
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
        let canonicalTarget = targetURL.resolvingSymlinksInPath().standardizedFileURL
        let canonicalStorage = storageURL.resolvingSymlinksInPath().standardizedFileURL

        let storagePath = canonicalStorage.path
        if canonicalTarget.path != storagePath && !canonicalTarget.path.hasPrefix(storagePath + "/") {
            throw DropValidationError.outsideStorage
        }

        let components = canonicalTarget.pathComponents
        if components.contains("..") || components.contains(".") {
            throw DropValidationError.pathTraversal
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
        var sanitized = name
        sanitized = sanitized.replacingOccurrences(of: "/", with: "-")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        sanitized = sanitized.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)

        if sanitized.utf8.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let base = (sanitized as NSString).deletingPathExtension
            var truncated = String(base.prefix(240))
            if !ext.isEmpty {
                truncated += "." + ext
            }
            sanitized = truncated
        }

        return sanitized
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
