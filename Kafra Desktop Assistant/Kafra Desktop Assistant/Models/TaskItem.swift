import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isDone = false
        self.createdAt = Date()
        self.completedAt = nil
    }
}
