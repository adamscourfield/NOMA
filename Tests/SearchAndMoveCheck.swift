import Foundation
import SwiftData

@main
struct SearchAndMoveCheck {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([Project.self, Note.self, NoteImage.self, NoteDocument.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: directory.appendingPathComponent("test.store"))])
        let context = ModelContext(container)
        let source = Project(name: "Source")
        let destination = Project(name: "Destination")
        context.insert(source)
        context.insert(destination)
        let note = Note(title: "Kitchen measurements", body: "Choose warmer oak")
        context.insert(note)
        note.project = source
        let other = Note(title: "Keep this note")
        context.insert(other)
        other.project = destination
        let archived = Note(title: "Kitchen archived")
        context.insert(archived)
        archived.project = destination
        archived.toggleComplete()
        precondition(note.matchesSearch("KITCHEN"), "Unpinned titles must match")
        precondition(note.matchesSearch("  warmer oak \n"), "Body and trimmed queries must match")
        precondition(!note.matchesSearch("missing") && !note.matchesSearch(" \n"))
        precondition(!archived.matchesSearch("Kitchen"), "Home search must exclude archived notes")
        note.isPinned = true
        let image = NoteImage(data: Data([1, 2, 3]))
        context.insert(image)
        image.note = note
        for ext in ["m4a", "pdf"] {
            let attachment = NoteDocument(data: Data([4, 5, 6]), fileName: ext, fileExtension: ext)
            context.insert(attachment)
            attachment.note = note
        }
        try context.save()
        let originalID = note.persistentModelID
        let createdAt = note.createdAt
        try note.move(to: destination, in: context)
        precondition(note.persistentModelID == originalID && note.createdAt == createdAt)
        precondition(!source.notes.contains { $0.persistentModelID == originalID })
        precondition(destination.notes.filter { $0.persistentModelID == originalID }.count == 1)
        try note.move(to: destination, in: context)
        precondition(destination.notes.filter { $0.persistentModelID == originalID }.count == 1)
        // A fresh context verifies persisted inverse relationships, not just UI state.
        let fresh = ModelContext(container)
        let moved = fresh.model(for: originalID) as! Note
        precondition(moved.project?.name == "Destination" && moved.isPinned && !moved.isArchived)
        precondition(moved.title == "Kitchen measurements" && moved.body == "Choose warmer oak")
        precondition(moved.images.first?.data == Data([1, 2, 3]))
        precondition(moved.sortedAudio.count == 1 && moved.sortedDocuments.count == 1)
        precondition(moved.documents.allSatisfy { $0.data == Data([4, 5, 6]) })
        // Moving an archived note must retain completion and archive dates.
        let completedAt = archived.completedAt
        try archived.move(to: source, in: context)
        precondition(archived.isArchived && archived.isDone && archived.completedAt == completedAt)
        try archived.move(to: destination, in: context)
        context.delete(source)
        try context.save()
        let final = ModelContext(container)
        let notes = try final.fetch(FetchDescriptor<Note>())
        precondition(notes.count == 3 && notes.contains { $0.persistentModelID == originalID })
        let photoCount = try final.fetchCount(FetchDescriptor<NoteImage>())
        let documentCount = try final.fetchCount(FetchDescriptor<NoteDocument>())
        precondition(photoCount == 1 && documentCount == 2)
        print("PASS: global active-note title/body search; whitespace/case handling; archive exclusion; move preserves identity, text, pin, dates and attachments; repeated move doesn't duplicate; deleting source preserves moved notes.")
    }
}
