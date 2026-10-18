import Foundation
import SwiftData

/// Uses only an isolated, temporary store; never touches installed app data.
@main
struct ProjectManagementCheck {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([Project.self, Note.self, NoteImage.self, NoteDocument.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: directory.appendingPathComponent("test.store"))])
        let context = ModelContext(container)
        let project = Project(name: "Original", icon: "folder")
        let untouched = Project(name: "Keep this project", icon: "book")
        context.insert(project)
        context.insert(untouched)
        for archived in [false, true] {
            let note = Note(title: archived ? "Archived note" : "Active note")
            context.insert(note)
            note.project = project
            note.isPinned = true
            if archived { note.toggleComplete() }
            let image = NoteImage(data: Data([1, 2, 3]))
            context.insert(image)
            image.note = note
            for ext in ["pdf", "m4a"] {
                let attachment = NoteDocument(data: Data([4, 5, 6]), fileName: "Attachment", fileExtension: ext)
                context.insert(attachment)
                attachment.note = note
            }
        }
        let keepNote = Note(title: "Keep this note")
        context.insert(keepNote)
        keepNote.project = untouched
        try context.save()
        let id = project.persistentModelID
        project.name = "Renamed project"
        project.icon = "house"
        try context.save()
        let fresh = ModelContext(container)
        let renamed = fresh.model(for: id) as! Project
        precondition(renamed.name == "Renamed project" && renamed.icon == "house")
        precondition(renamed.notes.count == 2 && renamed.activeNotes.count == 1 && renamed.archivedNotes.count == 1)
        precondition(renamed.notes.allSatisfy { $0.isPinned && $0.images.count == 1 && $0.documents.count == 2 })
        context.delete(project)
        try context.save()
        let verify = ModelContext(container)
        let projects = try verify.fetch(FetchDescriptor<Project>())
        let notes = try verify.fetch(FetchDescriptor<Note>())
        let photos = try verify.fetchCount(FetchDescriptor<NoteImage>())
        let documents = try verify.fetchCount(FetchDescriptor<NoteDocument>())
        precondition(projects.count == 1 && projects[0].name == "Keep this project")
        precondition(notes.count == 1 && notes[0].title == "Keep this note")
        precondition(photos == 0 && documents == 0)
        print("PASS: rename and icon persist; notes survive edits; deleting a project cascades through active/archived notes, pins, photos, documents and audio; unrelated project untouched.")
    }
}
