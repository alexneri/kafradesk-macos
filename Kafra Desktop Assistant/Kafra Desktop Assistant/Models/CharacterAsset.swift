import Foundation

enum CharacterEdition: String, Codable, CaseIterable, Identifiable {
    case original
    case sakura

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original"
        case .sakura: return "Sakura"
        }
    }
}

struct CharacterAsset: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let edition: CharacterEdition
    let imageName: String
    let blinkImageName: String?
}
