import AppKit

/// Borderless window that lets its SwiftUI content (the RO chrome) draw the
/// entire frame. Overrides key/main eligibility so text fields inside still work.
/// Shared by the Storage, Notes, and Tasks windows.
final class ROBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
