import Foundation
import SwiftData

@Model
final class Note {
    var title: String
    var body: String
    var isDone: Bool
    var isArchived: Bool
    var isPinned: Bool
    var createdAt: Date
    var completedAt: Date?

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \NoteImage.note)
    var images: [NoteImage] = []

    @Relationship(deleteRule: .cascade, inverse: \NoteDocument.note)
    var documents: [NoteDocument] = []

    init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
        self.isDone = false
        self.isArchived = false
        self.isPinned = false
        self.createdAt = .now
        self.completedAt = nil
    }

    var isEmpty: Bool {
        title.isEmpty && body.isEmpty && images.isEmpty && documents.isEmpty
    }

    var sortedImages: [NoteImage] {
        images.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedDocuments: [NoteDocument] {
        documents.filter { !$0.isAudio }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedAudio: [NoteDocument] {
        documents.filter(\.isAudio).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Ticking a note marks it done and archives it in one step; there is no
    /// separate "complete" vs "archive" state for the user to think about.
    func toggleComplete() {
        isDone.toggle()
        if isDone {
            completedAt = .now
            isArchived = true
        } else {
            completedAt = nil
            isArchived = false
        }
    }
}
