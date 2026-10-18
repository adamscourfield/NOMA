import SwiftUI
import SwiftData
import UIKit

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var noteToEdit: Note?
    @State private var completingNoteIDs: Set<PersistentIdentifier> = []
    @State private var searchText = ""

    private var filteredActiveNotes: [Note] {
        guard !searchText.isEmpty else { return project.activeNotes }
        return project.activeNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if project.activeNotes.isEmpty {
                ContentUnavailableView(
                    "Nothing Active",
                    systemImage: "checkmark.circle",
                    description: Text("Tap + to add a note.")
                )
                .listRowSeparator(.hidden)
            } else if filteredActiveNotes.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(filteredActiveNotes) { note in
                    NoteRowView(
                        note: note,
                        isCompleting: completingNoteIDs.contains(note.persistentModelID),
                        onToggle: { beginComplete(note) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { noteToEdit = note }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            note.isPinned.toggle()
                        } label: {
                            Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(Color.coral)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search this project")
        .navigationTitle(project.name.isEmpty ? "Untitled Project" : project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    ArchiveView(project: project)
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(action: createNote) {
                    Label("New Note", systemImage: "plus")
                }
            }
        }
        .sheet(item: $noteToEdit, onDismiss: pruneEmptyNotes) { note in
            NavigationStack {
                NoteDetailView(note: note)
            }
        }
    }

    /// Ticking a note plays a brief "filled, then collapsed" sequence before
    /// it actually archives, rather than vanishing from the list instantly.
    private func beginComplete(_ note: Note) {
        guard !completingNoteIDs.contains(note.persistentModelID) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            completingNoteIDs.insert(note.persistentModelID)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeInOut(duration: 0.25)) {
                note.toggleComplete()
                completingNoteIDs.remove(note.persistentModelID)
            }
        }
    }

    private func createNote() {
        let note = Note()
        note.project = project
        modelContext.insert(note)
        project.notes.append(note)
        noteToEdit = note
    }

    private func pruneEmptyNotes() {
        for note in project.notes where note.isEmpty && !note.isArchived {
            modelContext.delete(note)
        }
    }
}
