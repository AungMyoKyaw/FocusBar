import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var type: String
    var unlockedAt: Date
    var metadata: String?

    init(type: String, unlockedAt: Date = Date(), metadata: String? = nil) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = unlockedAt
        self.metadata = metadata
    }
}
