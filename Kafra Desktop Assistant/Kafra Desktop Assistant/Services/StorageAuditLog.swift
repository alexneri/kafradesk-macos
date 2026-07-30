import Foundation
import os

enum StorageAuditLog {
    private static let formatter = ISO8601DateFormatter()
    private static let queue = DispatchQueue(label: "moe.sei.kda.audit-log", qos: .utility)

    static func log(operation: String, file: URL, success: Bool) {
        let timestamp = formatter.string(from: Date())
        let name = file.lastPathComponent
        let entry = "\(timestamp) | \(operation) | \(name) | \(success ? "OK" : "FAIL")\n"

        // Serialize writes off the caller's thread. Ordering is preserved by the
        // serial queue; callers never block on disk I/O.
        queue.async {
            do {
                let logURL = AppPaths.auditLogURL
                let data = Data(entry.utf8)
                if FileManager.default.fileExists(atPath: logURL.path) {
                    let handle = try FileHandle(forWritingTo: logURL)
                    defer { try? handle.close() }
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                } else {
                    try data.write(to: logURL, options: .atomic)
                }
            } catch {
                AppLogger.storage.error("Audit log write failed: \(error.localizedDescription)")
            }
        }
    }
}
