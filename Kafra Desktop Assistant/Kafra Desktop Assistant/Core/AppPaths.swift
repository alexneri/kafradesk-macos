import Foundation

enum AppPaths {
    static let appSupportDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Kafra Desktop Assistant", isDirectory: true)
    }()

    static let storageDirectory: URL = {
        appSupportDirectory.appendingPathComponent("Storage", isDirectory: true)
    }()

    static let auditLogURL: URL = {
        appSupportDirectory.appendingPathComponent("audit.log")
    }()

    static func ensureDirectories() throws {
        try createDirectoryIfNeeded(appSupportDirectory)
        try createDirectoryIfNeeded(storageDirectory)
    }

    private static func createDirectoryIfNeeded(_ url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
