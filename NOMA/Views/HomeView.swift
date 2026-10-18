import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    @Query(filter: #Predicate<Note> { !$0.isArchived }, sort: \Note.createdAt, order: .reverse)
    private var activeNotes: [Note]

    @State private var projectToEdit: Project?
    @State private var projectToDelete: Project?
    @State private var deleteAfterEditing: Project?
    @State private var showingNewProject = false
    @State private var showAllPinned = false
    @State private var searchText = ""

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var pinnedNotes: [Note] { activeNotes.filter(\.isPinned) }
    private var matchingNotes: [Note] { activeNotes.filter { $0.matchesSearch(query) } }
    private var visiblePinnedNotes: [Note] {
        showAllPinned ? pinnedNotes : Array(pinnedNotes.prefix(4))
    }
    private var morePinnedCount: Int { pinnedNotes.count - visiblePinnedNotes.count }
    private var filteredProjects: [Project] {
        query.isEmpty ? projects : projects.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    private var noResults: Bool {
        !query.isEmpty && matchingNotes.isEmpty && filteredProjects.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if !query.isEmpty && !matchingNotes.isEmpty {
                    Section("Notes") {
                        ForEach(matchingNotes) { note in
                            NavigationLink(value: note) {
                                SearchNoteRow(note: note)
                            }
                        }
                    }
                }

                if query.isEmpty && !visiblePinnedNotes.isEmpty {
                    Section("Pinned") {
                        ForEach(visiblePinnedNotes) { note in
                            NavigationLink(value: note) {
                                PinnedNoteRow(note: note)
                            }
                        }
                        if morePinnedCount > 0 {
                            Button("+\(morePinnedCount) more pinned") {
                                withAnimation { showAllPinned = true }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.coral)
                        }
                    }
                }

                if !filteredProjects.isEmpty {
                    Section("Projects") {
                        ForEach(filteredProjects) { project in
                            NavigationLink(value: project) {
                                ProjectRowView(project: project)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    projectToDelete = project
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { projectToEdit = project } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.coral)
                            }
                            .contextMenu {
                                Button { projectToEdit = project } label: {
                                    Label("Edit Project", systemImage: "pencil")
                                }
                                Button(role: .destructive) { projectToDelete = project } label: {
                                    Label("Delete Project", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if noResults {
                    ContentUnavailableView.search(text: searchText)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search notes and projects")
            .navigationTitle("NOMA")
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if projects.isEmpty && pinnedNotes.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "folder",
                        description: Text("Tap + to create your first project.")
                    )
                }
            }
            .sheet(item: $projectToEdit, onDismiss: {
                if let project = deleteAfterEditing {
                    deleteAfterEditing = nil
                    modelContext.delete(project)
                }
            }) { project in
                EditProjectView(project: project) { deleteAfterEditing = project }
            }
            .alert("Delete this project?", isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            )) {
                Button("Delete Project", role: .destructive) {
                    if let project = projectToDelete { modelContext.delete(project) }
                    projectToDelete = nil
                }
                Button("Cancel", role: .cancel) { projectToDelete = nil }
            } message: {
                Text("“\(projectToDelete?.name ?? "This project")” and all its active and archived notes, photos, audio, and documents will be permanently deleted. This cannot be undone.")
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
        }
    }

}

private struct SearchNoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.coral)
                }
            }
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Label(note.project?.name ?? "No project", systemImage: note.project?.icon ?? "folder")
                .font(.caption)
                .foregroundStyle(Color.coral)
                .lineLimit(1)
        }
        .padding(.vertical, 3)
    }
}
