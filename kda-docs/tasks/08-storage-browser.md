# Task 08: Storage Browser

## Goal
Provide a simple file browser for the app's storage directory.

## Scope
- Display files and folders within `Application Support/Kafra Desktop Assistant/Storage`.
- Support open, reveal in Finder, delete, and new folder actions.
- Keep the list refreshed after file operations.

## Implementation Steps
1. Implement a `StorageService` that enumerates files in the storage folder and returns metadata (name, type, size, modified date).
2. Build a storage list view with actions for open and reveal in Finder.
3. Add actions for delete and create new folder with confirmation.
4. Refresh the list after every operation or when the window becomes active.
5. **Security: Implement file type validation and path sanitization.**
6. **Security: Add user warnings for opening executable content.**
7. **Security: Validate all file operations stay within storage directory bounds.**

## Security Requirements

### 🔴 Critical: Prevent Arbitrary Code Execution

The legacy Windows app had a **CRITICAL** vulnerability where `ShellExecute` could launch any file without validation. This must be fixed in the macOS port.

**Required Protections:**

1. **File Type Whitelisting for "Open" Action**

```swift
enum FileOpenSafety {
    case safe        // Documents, images, videos - open directly
    case caution     // Archives, PDFs - warn user
    case dangerous   // Executables, scripts - require explicit confirmation
    
    static func assess(_ url: URL) -> FileOpenSafety {
        let ext = url.pathExtension.lowercased()
        
        // Safe types
        let safeTyes = ["txt", "rtf", "pdf", "jpg", "jpeg", "png", "gif", 
                        "bmp", "tiff", "mp3", "mp4", "mov", "m4a"]
        if safeTyes.contains(ext) { return .safe }
        
        // Dangerous types
        let dangerousTypes = ["app", "command", "sh", "bash", "zsh", "py", 
                              "rb", "pl", "pkg", "dmg", "exe", "bat", "cmd"]
        if dangerousTypes.contains(ext) { return .dangerous }
        
        return .caution
    }
}

// In StorageService
func openFile(_ url: URL) throws {
    switch FileOpenSafety.assess(url) {
    case .safe:
        NSWorkspace.shared.open(url)
        
    case .caution:
        // Show warning dialog
        let alert = NSAlert()
        alert.messageText = "Open this file?"
        alert.informativeText = "'\(url.lastPathComponent)' may contain active content."
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
        
    case .dangerous:
        // Strong warning for executables
        let alert = NSAlert()
        alert.messageText = "⚠️ Security Warning"
        alert.informativeText = """
            '\(url.lastPathComponent)' is an executable file that could harm your Mac.
            
            Only open this if you trust its source.
            """
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Open Anyway")
        alert.alertStyle = .critical
        
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }
}
```

2. **Path Traversal Prevention**

```swift
// Validate all file operations stay within storage directory
class StorageService {
    let storageURL: URL
    
    func validatePath(_ url: URL) throws {
        // Resolve symbolic links and relative paths
        let canonicalURL = url.standardizedFileURL
        let canonicalStorage = storageURL.standardizedFileURL
        
        // Ensure path is within storage directory
        guard canonicalURL.path.hasPrefix(canonicalStorage.path) else {
            throw StorageError.pathTraversal(
                "File '\(url.lastPathComponent)' is outside storage directory"
            )
        }
        
        // Reject paths with suspicious components
        let pathComponents = canonicalURL.pathComponents
        if pathComponents.contains("..") || pathComponents.contains(".") {
            throw StorageError.invalidPath(
                "Path contains invalid components: \(url.path)"
            )
        }
    }
    
    func deleteFile(_ url: URL) throws {
        try validatePath(url)
        
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Delete '\(url.lastPathComponent)'?"
        alert.informativeText = "This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        
        try FileManager.default.removeItem(at: url)
    }
}

enum StorageError: LocalizedError {
    case pathTraversal(String)
    case invalidPath(String)
    case accessDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .pathTraversal(let msg): return "Path Traversal: \(msg)"
        case .invalidPath(let msg): return "Invalid Path: \(msg)"
        case .accessDenied(let msg): return "Access Denied: \(msg)"
        }
    }
}
```

3. **Sanitize File Names**

```swift
extension StorageService {
    func sanitizeFileName(_ name: String) -> String {
        // Remove path separators
        var sanitized = name.replacingOccurrences(of: "/", with: "-")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // Remove leading dots (hidden files)
        while sanitized.hasPrefix(".") {
            sanitized.removeFirst()
        }
        
        // Limit length
        if sanitized.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let base = (sanitized as NSString).deletingPathExtension
            sanitized = String(base.prefix(250)) + "." + ext
        }
        
        return sanitized.isEmpty ? "unnamed" : sanitized
    }
}
```

### 🟠 High: Audit Logging

```swift
// Log all file operations for security auditing
class StorageAuditLog {
    static func log(operation: String, file: URL, success: Bool) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "\(timestamp) | \(operation) | \(file.lastPathComponent) | \(success ? "✓" : "✗")"
        
        // Write to audit log
        let logURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Kafra Desktop Assistant")
            .appendingPathComponent("audit.log")
        
        if let logHandle = try? FileHandle(forWritingTo: logURL) {
            logHandle.seekToEndOfFile()
            if let data = (entry + "\n").data(using: .utf8) {
                logHandle.write(data)
            }
            try? logHandle.close()
        }
    }
}

// Usage
func openFile(_ url: URL) throws {
    defer { StorageAuditLog.log(operation: "OPEN", file: url, success: true) }
    // ... open logic
}
```

## Acceptance Criteria
- Storage view reflects current files on disk.
- Open and reveal actions work for files and folders.
- Deleting a file updates the list immediately.
- **Security: Executable files show security warning before opening.**
- **Security: All file paths are validated to prevent traversal attacks.**
- **Security: File operations are logged to audit trail.**
- **Security: User confirmations are required for destructive operations.**

## Notes/Dependencies
- Depends on `AppPaths` from Task 01.
- Review `kda-docs/explanation/security.md` for legacy vulnerabilities to avoid.