import AppKit
import SwiftUI

final class StorageWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Storage"
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(rootView: NavigationStack { StorageBrowserView() })

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
