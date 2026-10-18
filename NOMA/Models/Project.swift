import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var icon: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Note.project)
    var notes: [Note] = []

    init(name: String = "", icon: String = "folder") {
        self.name = name
        self.icon = icon
        self.createdAt = .now
    }

    var activeNotes: [Note] {
        notes
            .filter { !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.createdAt > rhs.createdAt
            }
    }

    var archivedNotes: [Note] {
        notes
            .filter(\.isArchived)
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }
}
