import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var noteToView: Note?

    var body: some View {
        List {
            if project.archivedNotes.isEmpty {
                ContentUnavailableView("Nothing Archived Yet", systemImage: "archivebox")
                    .listRowSeparator(.hidden)
            } else {
                ForEach(project.archivedNotes) { note in
                    ArchivedNoteRow(note: note)
                        .contentShape(Rectangle())
                        .onTapGesture { noteToView = note }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                restore(note)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color.coral)
                        }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $noteToView) { note in
            NavigationStack {
                NoteDetailView(note: note)
            }
        }
    }

    private func restore(_ note: Note) {
        withAnimation {
            note.isDone = false
            note.isArchived = false
            note.completedAt = nil
        }
    }
}

private struct ArchivedNoteRow: View {
    @Bindable var note: Note

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.coral)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .strikethrough()
                if let completedAt = note.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
