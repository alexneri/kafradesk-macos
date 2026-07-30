import AppKit
import Combine
import SwiftData
import SwiftUI

final class MascotWindowController: NSWindowController, NSWindowDelegate {
    private let appState: AppState
    private let catalog: CharacterCatalog
    private let modelContainer: ModelContainer

    /// Interaction callbacks, set by AppDelegate.
    var onShowNotes: (() -> Void)?
    var onShowTasks: (() -> Void)?
    var onShowStorage: (() -> Void)?
    var onSurfaceWindows: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private var mascotHostingView: MascotHostingView<AnyView>?

    init(appState: AppState, catalog: CharacterCatalog, modelContainer: ModelContainer) {
        self.appState = appState
        self.catalog = catalog
        self.modelContainer = modelContainer

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false // mascot drags itself (see MascotHostingView)
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        super.init(window: panel)
        window?.delegate = self

        let rootView = AnyView(
            MascotView()
                .environmentObject(appState)
                .environmentObject(catalog)
                .environment(\.modelContext, modelContainer.mainContext)
        )

        let hostingView = MascotHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.onSingleClick = { [weak self] in self?.onSurfaceWindows?() }
        hostingView.onShowMenu = { [weak self] location in
            self?.presentInteractionMenu(at: location)
        }
        panel.contentView = hostingView
        mascotHostingView = hostingView

        resizeToFit()
        applyWindowPositionIfAvailable()
        bindAppState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowDidMove(_ notification: Notification) {
        guard let origin = window?.frame.origin else { return }
        appState.windowPosition = origin
    }

    // MARK: - Interaction menu

    private func presentInteractionMenu(at locationInWindow: NSPoint) {
        guard let hostingView = mascotHostingView else { return }
        let menu = NSMenu()
        menu.addItem(menuItem("Notes", #selector(menuNotes)))
        menu.addItem(menuItem("Tasks", #selector(menuTasks)))
        menu.addItem(menuItem("Storage", #selector(menuStorage)))
        let point = hostingView.convert(locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: point, in: hostingView)
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func menuNotes() { onShowNotes?() }
    @objc private func menuTasks() { onShowTasks?() }
    @objc private func menuStorage() { onShowStorage?() }

    // MARK: - App state

    private func bindAppState() {
        appState.$alwaysOnTop
            .sink { [weak self] isOnTop in
                self?.window?.level = isOnTop ? .floating : .normal
            }
            .store(in: &cancellables)

        appState.$selectedCharacterID
            .sink { [weak self] _ in
                self?.resizeToFit()
            }
            .store(in: &cancellables)

        appState.$windowPosition
            .sink { [weak self] position in
                guard let self else { return }
                if position == nil {
                    self.applyDefaultPosition()
                }
            }
            .store(in: &cancellables)
    }

    private func resizeToFit() {
        guard let hostingView = mascotHostingView else { return }
        let size = hostingView.fittingSize
        if size.width > 0 && size.height > 0 {
            window?.setContentSize(size)
        }
    }

    private func applyWindowPositionIfAvailable() {
        guard let window = window else { return }
        if let position = appState.windowPosition {
            window.setFrameOrigin(position)
        } else {
            applyDefaultPosition()
        }
    }

    private func applyDefaultPosition() {
        guard let screen = NSScreen.main, let window = window else { return }
        let frame = screen.visibleFrame
        let size = window.frame.size
        let origin = CGPoint(
            x: frame.maxX - size.width - 40,
            y: frame.minY + 40
        )
        window.setFrameOrigin(origin)
    }
}
