import AppKit
import Combine

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    private let appState: AppState
    private let catalog: CharacterCatalog

    private let showMascot: () -> Void
    private let hideMascot: () -> Void
    private let showPreferences: () -> Void
    private let showMemos: () -> Void
    private let showStorage: () -> Void
    private let showAbout: () -> Void
    private let quit: () -> Void

    private var cancellables = Set<AnyCancellable>()

    private var showHideItem: NSMenuItem = NSMenuItem()
    private var characterMenuItem: NSMenuItem = NSMenuItem()
    private var editionMenuItem: NSMenuItem = NSMenuItem()

    init(
        appState: AppState,
        catalog: CharacterCatalog,
        showMascot: @escaping () -> Void,
        hideMascot: @escaping () -> Void,
        showPreferences: @escaping () -> Void,
        showMemos: @escaping () -> Void,
        showStorage: @escaping () -> Void,
        showAbout: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.appState = appState
        self.catalog = catalog
        self.showMascot = showMascot
        self.hideMascot = hideMascot
        self.showPreferences = showPreferences
        self.showMemos = showMemos
        self.showStorage = showStorage
        self.showAbout = showAbout
        self.quit = quit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Kafra Desktop Assistant")
        statusItem.button?.image?.isTemplate = true

        buildMenu()
        bindState()
    }

    private func buildMenu() {
        menu.removeAllItems()

        showHideItem = NSMenuItem(title: appState.isMascotVisible ? "Hide Mascot" : "Show Mascot", action: #selector(toggleMascot), keyEquivalent: "s")
        showHideItem.target = self
        menu.addItem(showHideItem)

        editionMenuItem = NSMenuItem(title: "Edition", action: nil, keyEquivalent: "")
        let editionMenu = NSMenu()
        for edition in CharacterEdition.allCases {
            let item = NSMenuItem(title: edition.displayName, action: #selector(selectEdition(_:)), keyEquivalent: "")
            item.target = self
            item.state = (edition == appState.selectedEdition) ? .on : .off
            item.representedObject = edition
            editionMenu.addItem(item)
        }
        editionMenuItem.submenu = editionMenu
        menu.addItem(editionMenuItem)

        characterMenuItem = NSMenuItem(title: "Character", action: nil, keyEquivalent: "")
        characterMenuItem.submenu = buildCharacterMenu()
        menu.addItem(characterMenuItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let memosItem = NSMenuItem(title: "Memos...", action: #selector(openMemos), keyEquivalent: "m")
        memosItem.target = self
        menu.addItem(memosItem)

        let storageItem = NSMenuItem(title: "Storage...", action: #selector(openStorage), keyEquivalent: "o")
        storageItem.target = self
        menu.addItem(storageItem)

        let aboutItem = NSMenuItem(title: "About Kafra Desktop Assistant", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func buildCharacterMenu() -> NSMenu {
        let menu = NSMenu()
        let characters = catalog.characters(for: appState.selectedEdition)
        for character in characters {
            let item = NSMenuItem(title: character.displayName, action: #selector(selectCharacter(_:)), keyEquivalent: "")
            item.target = self
            item.state = (character.id == appState.selectedCharacterID) ? .on : .off
            item.representedObject = character.id
            menu.addItem(item)
        }
        return menu
    }

    private func updateCharacterMenu() {
        characterMenuItem.submenu = buildCharacterMenu()
        if let editionMenu = editionMenuItem.submenu {
            for item in editionMenu.items {
                if let edition = item.representedObject as? CharacterEdition {
                    item.state = (edition == appState.selectedEdition) ? .on : .off
                }
            }
        }
    }

    private func bindState() {
        appState.$isMascotVisible
            .sink { [weak self] visible in
                self?.showHideItem.title = visible ? "Hide Mascot" : "Show Mascot"
            }
            .store(in: &cancellables)

        appState.$selectedCharacterID
            .sink { [weak self] _ in
                self?.updateCharacterMenu()
            }
            .store(in: &cancellables)

        appState.$selectedEdition
            .sink { [weak self] _ in
                self?.updateCharacterMenu()
            }
            .store(in: &cancellables)
    }

    @objc private func toggleMascot() {
        if appState.isMascotVisible {
            hideMascot()
        } else {
            showMascot()
        }
    }

    @objc private func selectCharacter(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String {
            appState.selectedCharacterID = id
        }
    }

    @objc private func selectEdition(_ sender: NSMenuItem) {
        if let edition = sender.representedObject as? CharacterEdition {
            appState.selectedEdition = edition
            if let fallback = catalog.defaultCharacter(for: edition) {
                appState.selectedCharacterID = fallback.id
            }
        }
    }

    @objc private func openPreferences() {
        showPreferences()
    }

    @objc private func openMemos() {
        showMemos()
    }

    @objc private func openStorage() {
        showStorage()
    }

    @objc private func openAbout() {
        showAbout()
    }

    @objc private func quitApp() {
        quit()
    }
}
