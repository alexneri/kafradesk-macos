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
    private var storageWindowController: StorageWindowController?
    private var aboutWindowController: AboutWindowController?
    private var statusBarController: StatusBarController?

    override init() {
        let schema = Schema([
            Memo.self,
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

        _ = BlurbController.shared
        mascotWindowController = MascotWindowController(
            appState: appState,
            catalog: characterCatalog,
            modelContainer: modelContainer
        )

        preferencesWindowController = PreferencesWindowController(appState: appState, catalog: characterCatalog)
        memoWindowController = MemoWindowController(modelContainer: modelContainer)
        storageWindowController = StorageWindowController()
        aboutWindowController = AboutWindowController()

        statusBarController = StatusBarController(
            appState: appState,
            catalog: characterCatalog,
            showMascot: { [weak self] in self?.showMascot() },
            hideMascot: { [weak self] in self?.hideMascot() },
            showPreferences: { [weak self] in self?.showPreferences() },
            showMemos: { [weak self] in self?.showMemos() },
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
        appState.$isMascotVisible
            .sink { [weak self] isVisible in
                self?.applyMascotVisibility(isVisible)
                self?.savePreferences()
            }
            .store(in: &cancellables)

        appState.$alwaysOnTop
            .sink { [weak self] _ in self?.savePreferences() }
            .store(in: &cancellables)

        appState.$selectedCharacterID
            .sink { [weak self] _ in self?.savePreferences() }
            .store(in: &cancellables)

        appState.$selectedEdition
            .sink { [weak self] _ in self?.savePreferences() }
            .store(in: &cancellables)

        appState.$animationsEnabled
            .sink { [weak self] _ in self?.savePreferences() }
            .store(in: &cancellables)

        appState.$windowPosition
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
