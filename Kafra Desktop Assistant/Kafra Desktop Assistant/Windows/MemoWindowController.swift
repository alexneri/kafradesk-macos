import AppKit
import SwiftData
import SwiftUI

final class MemoWindowController: NSWindowController {
    init(modelContainer: ModelContainer) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Memos"
        window.isReleasedWhenClosed = false

        let rootView = MemoListView()
            .environment(\.modelContext, modelContainer.mainContext)

        window.contentView = NSHostingView(rootView: rootView)

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
