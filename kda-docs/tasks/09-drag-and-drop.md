# Task 09: Drag and Drop Integration

## Goal
Support dropping files onto the mascot or storage view to copy them into the app's storage folder **with proper security validation**.

## Scope
- Accept file drops from Finder into the mascot or storage UI.
- Copy dropped files into the storage directory, handling name collisions.
- Provide basic feedback for successful or failed drops.
- **Security: Validate and sanitize all dropped file paths.**
- **Security: Prevent directory traversal and symlink attacks.**
- **Security: Implement file size and type restrictions.**

## Implementation Steps
1. Add `onDrop` handlers to the mascot view and storage list view.
2. Resolve dropped URLs from `NSItemProvider` and validate file types.
3. **Security: Sanitize file names and validate paths before copying.**
4. Copy files into the storage folder, appending a suffix on name conflicts.
5. Trigger a storage list refresh and show a brief success message.
6. **Security: Implement drop validation and rejection criteria.**

## Security Requirements

### 🔴 Critical: Path Traversal and Symlink Prevention

The legacy Windows app allowed unchecked file moves that could be exploited with crafted filenames. The macOS port must validate all dropped paths.

**Required Protections:**

1. **Validate Dropped URLs**

```swift
class DropValidator {
    enum DropValidationError: LocalizedError {
        case pathTraversal
        case symlinkDetected
        case fileTooLarge
        case invalidName
        case forbiddenType
        case outsideStorage
        
        var errorDescription: String? {
            switch self {
            case .pathTraversal: return "File path contains invalid traversal"
            case .symlinkDetected: return "Symbolic links are not allowed"
            case .fileTooLarge: return "File exceeds maximum size limit"
            case .invalidName: return "File name contains invalid characters"
            case .forbiddenType: return "File type is not allowed"
            case .outsideStorage: return "Target path is outside storage directory"
            }
        }
    }
    
    static let maxFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
    
    static func validateDroppedFile(_ url: URL, storageURL: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // 1. Check if file exists and is accessible
        guard fileManager.fileExists(atPath: url.path) else {
            throw DropValidationError.invalidName
        }
        
        // 2. Resolve symbolic links
        let resolvedURL = url.resolvingSymlinksInPath()
        if resolvedURL != url {
            throw DropValidationError.symlinkDetected
        }
        
        // 3. Check file size
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64,
           fileSize > maxFileSize {
            throw DropValidationError.fileTooLarge
        }
        
        // 4. Sanitize filename
        let sanitizedName = sanitizeFileName(url.lastPathComponent)
        guard !sanitizedName.isEmpty else {
            throw DropValidationError.invalidName
        }
        
        // 5. Build target URL
        let targetURL = storageURL.appendingPathComponent(sanitizedName)
        
        // 6. Validate target is within storage directory
        let canonicalTarget = targetURL.standardizedFileURL
        let canonicalStorage = storageURL.standardizedFileURL
        
        guard canonicalTarget.path.hasPrefix(canonicalStorage.path) else {
            throw DropValidationError.outsideStorage
        }
        
        // 7. Check for path traversal in components
        let components = canonicalTarget.pathComponents
        if components.contains("..") {
            throw DropValidationError.pathTraversal
        }
        
        return targetURL
    }
    
    static func sanitizeFileName(_ name: String) -> String {
        var sanitized = name
        
        // Remove path separators
        sanitized = sanitized.replacingOccurrences(of: "/", with: "-")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
        
        // Remove control characters and null bytes
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // Remove leading/trailing dots and spaces
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        
        // Replace multiple spaces with single space
        sanitized = sanitized.replacingOccurrences(of: "  +", 
                                                    with: " ", 
                                                    options: .regularExpression)
        
        // Limit length (macOS max is 255 bytes)
        if sanitized.utf8.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let base = (sanitized as NSString).deletingPathExtension
            
            // Keep extension, truncate base
            var truncated = String(base.prefix(240))
            if !ext.isEmpty {
                truncated += "." + ext
            }
            sanitized = truncated
        }
        
        return sanitized
    }
}
```

2. **Implement Safe File Copy with Collision Handling**

```swift
class DropHandler {
    let storageURL: URL
    
    func handleDrop(urls: [URL]) async -> DropResult {
        var succeeded: [String] = []
        var failed: [(String, Error)] = []
        
        for url in urls {
            do {
                // Validate the dropped file
                let targetURL = try DropValidator.validateDroppedFile(url, storageURL: storageURL)
                
                // Handle name collisions
                let finalURL = try resolveCollision(targetURL)
                
                // Copy file (not move - preserve original)
                try FileManager.default.copyItem(at: url, to: finalURL)
                
                succeeded.append(finalURL.lastPathComponent)
                
                // Log for audit
                StorageAuditLog.log(operation: "DROP", file: finalURL, success: true)
                
            } catch {
                failed.append((url.lastPathComponent, error))
                StorageAuditLog.log(operation: "DROP_FAILED", file: url, success: false)
            }
        }
        
        return DropResult(succeeded: succeeded, failed: failed)
    }
    
    func resolveCollision(_ url: URL) throws -> URL {
        let fileManager = FileManager.default
        var candidateURL = url
        var counter = 1
        
        // Find available filename
        while fileManager.fileExists(atPath: candidateURL.path) {
            let baseName = (url.deletingPathExtension().lastPathComponent)
            let ext = url.pathExtension
            let newName = ext.isEmpty 
                ? "\(baseName) (\(counter))"
                : "\(baseName) (\(counter)).\(ext)"
            
            candidateURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
            
            // Prevent infinite loop
            if counter > 1000 {
                throw DropValidator.DropValidationError.invalidName
            }
        }
        
        return candidateURL
    }
}

struct DropResult {
    let succeeded: [String]
    let failed: [(String, Error)]
    
    var successCount: Int { succeeded.count }
    var failureCount: Int { failed.count }
    
    var message: String {
        if failureCount == 0 {
            return succeeded.count == 1 
                ? "Added '\(succeeded[0])'"
                : "Added \(succeeded.count) files"
        } else if successCount == 0 {
            return "Failed to add \(failureCount) file(s)"
        } else {
            return "Added \(successCount), failed \(failureCount)"
        }
    }
}
```

3. **SwiftUI Drop Handler Implementation**

```swift
struct MascotView: View {
    @EnvironmentObject var appState: AppState
    @State private var isDropTarget = false
    
    var body: some View {
        Image(appState.currentCharacter.imageName)
            .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
                handleDrop(providers: providers)
                return true
            }
            .overlay(
                // Visual feedback during drag
                isDropTarget ? 
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                    : nil
            )
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    if let url = try? await provider.loadItem(
                        forTypeIdentifier: UTType.fileURL.identifier
                    ) as? URL {
                        urls.append(url)
                    }
                }
            }
            
            guard !urls.isEmpty else { return }
            
            let dropHandler = DropHandler(storageURL: AppPaths.storageDirectory)
            let result = await dropHandler.handleDrop(urls: urls)
            
            // Show result notification
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .filesDropped,
                    object: nil,
                    userInfo: ["result": result]
                )
            }
        }
    }
}

extension Notification.Name {
    static let filesDropped = Notification.Name("filesDropped")
}
```

### 🟠 High: File Type and Size Restrictions

```swift
extension DropValidator {
    // Forbidden file types (security risk)
    static let forbiddenExtensions = [
        "command",  // macOS shell script
        "terminal", // Terminal profile
        "workflow", // Automator workflow
        "scpt",     // AppleScript
        "scptd",    // AppleScript bundle
        "applescript",
        "action"    // Automator action
    ]
    
    static func validateFileType(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        
        if forbiddenExtensions.contains(ext) {
            throw DropValidationError.forbiddenType
        }
        
        // Check if it's an app bundle
        if ext == "app" {
            // Warn but allow (user might want to store app bundles)
            // Log as high-risk operation
            StorageAuditLog.log(
                operation: "DROP_APP_BUNDLE",
                file: url,
                success: true
            )
        }
    }
}
```

### 🟡 Medium: User Feedback and Warnings

```swift
class DropFeedbackController {
    static func showDropResult(_ result: DropResult, in window: NSWindow?) {
        if result.failureCount > 0 {
            // Show detailed error for failures
            let alert = NSAlert()
            alert.messageText = "Some files could not be added"
            
            let failureList = result.failed
                .map { "• \($0.0): \($0.1.localizedDescription)" }
                .joined(separator: "\n")
            
            alert.informativeText = """
                Successfully added: \(result.successCount)
                Failed: \(result.failureCount)
                
                Errors:
                \(failureList)
                """
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            
            if let window = window {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        } else {
            // Show brief success notification (Task 10 blurb)
            BlurbController.shared.show(
                message: result.message,
                icon: .success,
                duration: 2.0
            )
        }
    }
}
```

## Acceptance Criteria
- Dropping one or more files places them into the storage folder.
- Name collisions are handled without overwriting existing files.
- The storage list updates immediately after a drop.
- **Security: File paths are validated before copying (no traversal).**
- **Security: Symbolic links are rejected or resolved safely.**
- **Security: Forbidden file types are blocked with clear error messages.**
- **Security: File size limits are enforced (default 100 MB).**
- **Security: Original files are copied, not moved (preserve user data).**
- **Security: Drop operations are logged to audit trail.**
- **UX: Visual feedback shows drop target highlight.**
- **UX: Success/failure notifications are clear and actionable.**

## Notes/Dependencies
- Depends on Task 08 for the storage browser and Task 03 for mascot view wiring.
- Depends on Task 10 for blurb notifications.
- Review `kda-docs/explanation/security.md` for legacy path traversal vulnerabilities.

## Testing Checklist

```markdown
### Security Testing

- [ ] Drop file with "../" in name → rejected
- [ ] Drop symbolic link → rejected or resolved safely
- [ ] Drop file >100 MB → rejected with clear message
- [ ] Drop file with null bytes in name → sanitized
- [ ] Drop file with path separators → sanitized
- [ ] Drop .command file → rejected
- [ ] Drop .app bundle → allowed with warning logged
- [ ] Drop 1000 files with same name → collision handling works
- [ ] Drop file to full disk → graceful error handling
- [ ] Drop file without read permission → clear error message

### Functionality Testing

- [ ] Drop single file → copied successfully
- [ ] Drop multiple files → all copied
- [ ] Drop file with existing name → numbered copy created
- [ ] Drop folder → handled appropriately
- [ ] Drop while storage view closed → works via mascot
- [ ] Drop shows visual feedback (highlight)
- [ ] Success notification displays briefly
- [ ] Failure alert shows detailed errors
- [ ] Storage list refreshes after drop
```