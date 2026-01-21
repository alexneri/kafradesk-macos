import Combine
import Foundation
import os

final class CharacterCatalog: ObservableObject {
    @Published private(set) var characters: [CharacterAsset]

    init(characters: [CharacterAsset] = []) {
        if characters.isEmpty {
            self.characters = CharacterCatalog.loadFromBundle()
        } else {
            self.characters = characters
        }
    }

    func characters(for edition: CharacterEdition) -> [CharacterAsset] {
        characters.filter { $0.edition == edition }
    }

    func character(id: String) -> CharacterAsset? {
        characters.first { $0.id == id }
    }

    func defaultCharacter(for edition: CharacterEdition) -> CharacterAsset? {
        characters(for: edition).first
    }

    private static func loadFromBundle() -> [CharacterAsset] {
        guard let url = Bundle.main.url(forResource: "CharacterCatalog", withExtension: "json") else {
            AppLogger.app.error("CharacterCatalog.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([CharacterAsset].self, from: data)
        } catch {
            AppLogger.app.error("Failed to load CharacterCatalog.json: \(error.localizedDescription)")
            return []
        }
    }
}
