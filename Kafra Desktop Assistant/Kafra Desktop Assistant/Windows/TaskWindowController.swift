import AppKit
import SwiftData
import SwiftUI

final class TaskWindowController: NSWindowController {
    init(modelContainer: ModelContainer) {
        let window = ROBorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 340),
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

        let rootView = ROTasksView(onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })
        .environment(\.modelContext, modelContainer.mainContext)

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
