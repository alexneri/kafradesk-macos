import AppKit
import Combine
import SwiftData
import SwiftUI
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferencesStore = PreferencesStore()
    private let characterCatalog = CharacterCatalog()

    private(set) var appState: AppState
    private(set) var modelContainer: ModelContainer

    private var cancellables = Set<AnyCancellable>()

    private var mascotWindowController: MascotWindowController?
    private var preferencesWindowController: PreferencesWindowController?
    private var memoWindowController: MemoWindowController?
    private var taskWindowController: TaskWindowController?
    private var storageWindowController: StorageWindowController?
    private var aboutWindowController: AboutWindowController?
    private var statusBarController: StatusBarController?

    override init() {
        let schema = Schema([
            Memo.self,
            TaskItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let preferences = preferencesStore.load()
        self.appState = AppState(preferences: preferences)

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            try AppPaths.ensureDirectories()
        } catch {
            AppLogger.app.error("Failed to create app directories: \(error.localizedDescription)")
        }

        appState.updateSelectedCharacterIfNeeded(characterCatalog)
        savePreferences()
        bindPreferences()

        // Warm the image cache off the main thread so the mascot's first paint
        // doesn't pay for the color-key pass.
        CharacterImageProvider.prewarm(characterCatalog.allImageNames)

        _ = BlurbController.shared
        mascotWindowController = MascotWindowController(
            appState: appState,
            catalog: characterCatalog,
            modelContainer: modelContainer
        )

        preferencesWindowController = PreferencesWindowController(appState: appState, catalog: characterCatalog)
        memoWindowController = MemoWindowController(modelContainer: modelContainer)
        taskWindowController = TaskWindowController(modelContainer: modelContainer)
        storageWindowController = StorageWindowController()
        aboutWindowController = AboutWindowController()

        mascotWindowController?.onShowNotes = { [weak self] in self?.showMemos() }
        mascotWindowController?.onShowTasks = { [weak self] in self?.showTasks() }
        mascotWindowController?.onShowStorage = { [weak self] in self?.showStorage() }
        mascotWindowController?.onSurfaceWindows = { [weak self] in self?.surfaceOpenWindows() }

        statusBarController = StatusBarController(
            appState: appState,
            catalog: characterCatalog,
            showMascot: { [weak self] in self?.showMascot() },
            hideMascot: { [weak self] in self?.hideMascot() },
            showPreferences: { [weak self] in self?.showPreferences() },
            showMemos: { [weak self] in self?.showMemos() },
            showTasks: { [weak self] in self?.showTasks() },
            showStorage: { [weak self] in self?.showStorage() },
            showAbout: { [weak self] in self?.showAbout() },
            quit: { [weak self] in self?.quit() }
        )

        applyMascotVisibility(appState.isMascotVisible)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func bindPreferences() {
        // Mascot visibility has a side effect (show/hide) beyond persistence.
        appState.$isMascotVisible
            .sink { [weak self] isVisible in
                self?.applyMascotVisibility(isVisible)
                self?.savePreferences()
            }
            .store(in: &cancellables)

        // Discrete preference changes: persist immediately, on one merged stream.
        Publishers.Merge4(
            appState.$alwaysOnTop.map { _ in () },
            appState.$selectedCharacterID.map { _ in () },
            appState.$selectedEdition.map { _ in () },
            appState.$animationsEnabled.map { _ in () }
        )
        .sink { [weak self] in self?.savePreferences() }
        .store(in: &cancellables)

        // Window position fires continuously while dragging the mascot; debounce
        // so we don't JSON-encode + write UserDefaults on every drag tick.
        appState.$windowPosition
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.savePreferences() }
            .store(in: &cancellables)
    }

    private func savePreferences() {
        preferencesStore.save(appState.toPreferences())
    }

    private func showMascot() {
        appState.isMascotVisible = true
    }

    private func hideMascot() {
        appState.isMascotVisible = false
    }

    private func applyMascotVisibility(_ isVisible: Bool) {
        if isVisible {
            mascotWindowController?.showWindow(nil)
            mascotWindowController?.window?.orderFrontRegardless()
        } else {
            mascotWindowController?.window?.orderOut(nil)
        }
    }

    private func showPreferences() {
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showMemos() {
        memoWindowController?.showWindow(nil)
        memoWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showTasks() {
        taskWindowController?.showWindow(nil)
        taskWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Bring every currently-open tool window to the front (single-click mascot).
    private func surfaceOpenWindows() {
        let windows = [
            memoWindowController?.window,
            taskWindowController?.window,
            storageWindowController?.window,
            preferencesWindowController?.window,
            aboutWindowController?.window
        ].compactMap { $0 }.filter { $0.isVisible }

        guard !windows.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)
        for window in windows {
            window.orderFront(nil)
        }
        windows.last?.makeKey()
    }

    private func showStorage() {
        storageWindowController?.showWindow(nil)
        storageWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showAbout() {
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func quit() {
        NSApp.terminate(nil)
    }
}
