import Combine
import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var isMascotVisible: Bool
    @Published var alwaysOnTop: Bool
    @Published var selectedCharacterID: String
    @Published var selectedEdition: CharacterEdition
    @Published var animationsEnabled: Bool
    @Published var windowPosition: CGPoint?

    init(preferences: Preferences) {
        self.isMascotVisible = preferences.isMascotVisible
        self.alwaysOnTop = preferences.alwaysOnTop
        self.selectedCharacterID = preferences.selectedCharacterID
        self.selectedEdition = preferences.selectedEdition
        self.animationsEnabled = preferences.animationsEnabled
        if let position = preferences.windowPosition {
            self.windowPosition = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
        } else {
            self.windowPosition = nil
        }
    }

    func updateSelectedCharacterIfNeeded(_ catalog: CharacterCatalog) {
        if catalog.character(id: selectedCharacterID) == nil {
            if let fallback = catalog.defaultCharacter(for: selectedEdition) {
                selectedCharacterID = fallback.id
            }
        }
    }

    func toPreferences() -> Preferences {
        Preferences(
            selectedCharacterID: selectedCharacterID,
            selectedEdition: selectedEdition,
            isMascotVisible: isMascotVisible,
            alwaysOnTop: alwaysOnTop,
            animationsEnabled: animationsEnabled,
            windowPosition: windowPosition.map { WindowPosition(x: Double($0.x), y: Double($0.y)) }
        )
    }
}
