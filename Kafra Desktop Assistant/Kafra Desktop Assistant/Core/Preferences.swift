import Foundation
import os

struct Preferences: Codable {
    var selectedCharacterID: String
    var selectedEdition: CharacterEdition
    var isMascotVisible: Bool
    var alwaysOnTop: Bool
    var animationsEnabled: Bool
    var windowPosition: WindowPosition?

    static func `default`() -> Preferences {
        Preferences(
            selectedCharacterID: "",
            selectedEdition: .original,
            isMascotVisible: true,
            alwaysOnTop: false,
            animationsEnabled: true,
            windowPosition: nil
        )
    }
}

struct WindowPosition: Codable {
    let x: Double
    let y: Double
}

final class PreferencesStore {
    private let defaults: UserDefaults
    private let key = "kafra.preferences"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Preferences {
        guard let data = defaults.data(forKey: key) else {
            return Preferences.default()
        }
        do {
            return try JSONDecoder().decode(Preferences.self, from: data)
        } catch {
            AppLogger.app.error("Failed to decode preferences: \(error.localizedDescription)")
            return Preferences.default()
        }
    }

    func save(_ preferences: Preferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            defaults.set(data, forKey: key)
        } catch {
            AppLogger.app.error("Failed to encode preferences: \(error.localizedDescription)")
        }
    }
}
