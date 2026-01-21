import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    init(appState: AppState, catalog: CharacterCatalog) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false

        let rootView = PreferencesView()
            .environmentObject(appState)
            .environmentObject(catalog)

        window.contentView = NSHostingView(rootView: rootView)

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
