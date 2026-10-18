import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    @Query(filter: #Predicate<Note> { $0.isPinned && !$0.isArchived }, sort: \Note.createdAt, order: .reverse)
    private var pinnedNotes: [Note]

    @State private var projectToEdit: Project?
    @State private var projectToDelete: Project?
    @State private var deleteAfterEditing: Project?
    @State private var showingNewProject = false
    @State private var showAllPinned = false
    @State private var searchText = ""

    private var filteredPinnedNotes: [Note] {
        guard !searchText.isEmpty else { return pinnedNotes }
        return pinnedNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var visiblePinnedNotes: [Note] {
        guard searchText.isEmpty, !showAllPinned else { return filteredPinnedNotes }
        return Array(filteredPinnedNotes.prefix(4))
    }

    private var morePinnedCount: Int {
        filteredPinnedNotes.count - visiblePinnedNotes.count
    }

    private var filteredProjects: [Project] {
        guard !searchText.isEmpty else { return projects }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var noResults: Bool {
        !searchText.isEmpty && filteredPinnedNotes.isEmpty && filteredProjects.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if !visiblePinnedNotes.isEmpty {
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
