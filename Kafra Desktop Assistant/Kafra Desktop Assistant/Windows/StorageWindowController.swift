import AppKit
import SwiftUI

/// Borderless window that lets its content (the RO chrome) draw the entire
/// frame. Overrides key/main eligibility so text fields inside still work.
private final class ROBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class StorageWindowController: NSWindowController {
    init() {
        let window = ROBorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let rootView = ROStorageView(onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
