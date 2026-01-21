import AppKit
import Combine
import SwiftData
import SwiftUI

final class MascotWindowController: NSWindowController, NSWindowDelegate {
    private let appState: AppState
    private let catalog: CharacterCatalog
    private let modelContainer: ModelContainer

    private var cancellables = Set<AnyCancellable>()

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
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        super.init(window: panel)
        window?.delegate = self

        let rootView = MascotView()
            .environmentObject(appState)
            .environmentObject(catalog)
            .environment(\.modelContext, modelContainer.mainContext)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView

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
        guard let hostingView = window?.contentView as? NSHostingView<MascotView> else { return }
        let size = hostingView.fittingSize
        if size.width > 0 && size.height > 0 {
            window?.setContentSize(size)
        }
    }

    private func applyWindowPositionIfAvailable() {
        guard let window = window else { return }
        if let position = appState.windowPosition {
            window.setFrameOrigin(position)
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = window.frame.size
            let origin = CGPoint(
                x: frame.maxX - size.width - 40,
                y: frame.minY + 40
            )
            window.setFrameOrigin(origin)
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
