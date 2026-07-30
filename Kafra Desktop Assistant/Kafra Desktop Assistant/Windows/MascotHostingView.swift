import AppKit
import SwiftUI

/// Hosting view for the mascot that distinguishes single-click, double-click,
/// and right-click, and drags the window manually (so a click that doesn't move
/// is treated as a click, not a drag). File drops handled by the SwiftUI content
/// still work — drops are not mouse events.
final class MascotHostingView<Content: View>: NSHostingView<Content> {
    /// Fired on a clean single click (no drag, no second click).
    var onSingleClick: (() -> Void)?
    /// Fired on double-click or right-click; passes the click location in window coords.
    var onShowMenu: ((NSPoint) -> Void)?

    private var mouseDownScreen: NSPoint = .zero
    private var originAtMouseDown: NSPoint = .zero
    private var didDrag = false
    private let dragThreshold: CGFloat = 3
    private var pendingSingleClick: DispatchWorkItem?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        didDrag = false
        mouseDownScreen = NSEvent.mouseLocation
        originAtMouseDown = window?.frame.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - mouseDownScreen.x
        let dy = now.y - mouseDownScreen.y
        if !didDrag, abs(dx) > dragThreshold || abs(dy) > dragThreshold {
            didDrag = true
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
        }
        if didDrag {
            window.setFrameOrigin(NSPoint(x: originAtMouseDown.x + dx, y: originAtMouseDown.y + dy))
        }
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag { return }
        if event.clickCount >= 2 {
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
            onShowMenu?(event.locationInWindow)
        } else if event.clickCount == 1 {
            // Defer the single-click action so a second click (double) can cancel it.
            let work = DispatchWorkItem { [weak self] in self?.onSingleClick?() }
            pendingSingleClick = work
            DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: work)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        pendingSingleClick?.cancel()
        pendingSingleClick = nil
        onShowMenu?(event.locationInWindow)
    }
}
