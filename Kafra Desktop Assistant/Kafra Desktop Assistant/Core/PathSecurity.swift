import Foundation

/// Single source of truth for filename sanitization and storage-containment
/// checks. Consolidates the previously duplicated (and slightly divergent)
/// implementations in `StorageService` and `DropValidator` so the security
/// rules cannot drift apart.
enum PathSecurity {

    /// Reason a URL fails the storage-containment check. Callers map this to
    /// their own domain error so user-facing messaging stays specific.
    enum Containment {
        case outside            // resolves to a path outside the storage root
        case invalidComponents  // contains "." or ".." path components
    }

    /// Sanitize a proposed file/folder name into something safe to place inside
    /// the storage directory. Superset of the old two implementations: strips
    /// path separators, control characters and NULs, collapses whitespace runs,
    /// trims leading/trailing dots and spaces (blocks hidden dotfiles), and
    /// enforces a 255-byte length ceiling while preserving the extension.
    static func sanitizeFileName(_ name: String) -> String {
        var sanitized = name
        sanitized = sanitized.replacingOccurrences(of: "/", with: "-")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "-")
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        sanitized = sanitized.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ". "))

        if sanitized.utf8.count > 255 {
            let ns = sanitized as NSString
            let ext = ns.pathExtension
            let base = ns.deletingPathExtension
            var truncated = String(base.prefix(240))
            if !ext.isEmpty {
                truncated += "." + ext
            }
            sanitized = truncated
        }

        return sanitized
    }

    /// Returns a containment failure reason, or `nil` when `url` safely resolves
    /// to `base` itself or a descendant of it.
    static func containmentViolation(for url: URL, within base: URL) -> Containment? {
        let canonicalURL = url.resolvingSymlinksInPath().standardizedFileURL
        let canonicalBase = base.resolvingSymlinksInPath().standardizedFileURL

        let basePath = canonicalBase.path
        if canonicalURL.path != basePath && !canonicalURL.path.hasPrefix(basePath + "/") {
            return .outside
        }

        let components = canonicalURL.pathComponents
        if components.contains("..") || components.contains(".") {
            return .invalidComponents
        }

        return nil
    }
}
