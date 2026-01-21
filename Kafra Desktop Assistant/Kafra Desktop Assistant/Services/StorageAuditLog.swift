import Foundation
import os

enum StorageAuditLog {
    static func log(operation: String, file: URL, success: Bool) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "\(timestamp) | \(operation) | \(file.lastPathComponent) | \(success ? "OK" : "FAIL")"

        do {
            let logURL = AppPaths.auditLogURL
            let data = (entry + "\n").data(using: .utf8) ?? Data()
            if FileManager.default.fileExists(atPath: logURL.path) {
                let handle = try FileHandle(forWritingTo: logURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: logURL, options: .atomic)
            }
        } catch {
            AppLogger.storage.error("Audit log write failed: \(error.localizedDescription)")
        }
    }
}
