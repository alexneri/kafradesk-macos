import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var body: String

    init(body: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.body = body
    }
}
