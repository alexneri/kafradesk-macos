import AppKit
import SwiftUI

final class BlurbWindowController: NSWindowController {
    private var hostingView: NSHostingView<BlurbView>?

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true

        super.init(window: panel)

        update(message: "", icon: .info)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(message: String, icon: BlurbIcon) {
        let view = BlurbView(message: message, iconName: icon.systemName)
        let hostingView = NSHostingView(rootView: view)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        window?.contentView = hostingView
        self.hostingView = hostingView

        let fittingSize = hostingView.fittingSize
        window?.setContentSize(fittingSize)

        positionWindow()
    }

    private func positionWindow() {
        guard let screen = NSScreen.main, let window = window else { return }
        let frame = screen.visibleFrame
        let size = window.frame.size
        let origin = CGPoint(
            x: frame.maxX - size.width - 20,
            y: frame.maxY - size.height - 40
        )
        window.setFrameOrigin(origin)
    }
}
