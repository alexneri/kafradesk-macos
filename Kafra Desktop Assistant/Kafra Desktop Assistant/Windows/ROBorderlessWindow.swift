import AppKit
import SwiftUI

/// Borderless window that lets its SwiftUI content (the RO chrome) draw the
/// entire frame. Overrides key/main eligibility so text fields inside still work.
/// `.resizable` in the style mask lets it be resized by dragging its edges even
/// though it is borderless. Shared by the Storage, Notes, and Tasks windows.
final class ROBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Builds and positions the RO tool windows so they are resizable and open
/// cascaded (rather than stacked exactly on top of each other).
enum ROWindowFactory {
    private static var cascadeIndex = 0

    static func makeWindow(width: CGFloat, height: CGFloat,
                           minWidth: CGFloat, minHeight: CGFloat) -> ROBorderlessWindow {
        let window = ROBorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: minWidth, height: minHeight)
        return window
    }

    /// Host a SwiftUI root view that fills (and resizes with) the window.
    static func install<V: View>(_ rootView: V, in window: NSWindow) {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = window.contentLayoutRect
        window.contentView = hostingView
    }

    static func cascade(_ window: NSWindow) {
        guard let screen = NSScreen.main else { window.center(); return }
        let visible = screen.visibleFrame
        let step: CGFloat = 30
        let i = CGFloat(cascadeIndex % 6)
        let origin = NSPoint(
            x: visible.minX + 140 + i * step,
            y: visible.maxY - window.frame.height - 90 - i * step
        )
        window.setFrameOrigin(origin)
        cascadeIndex += 1
    }
}
