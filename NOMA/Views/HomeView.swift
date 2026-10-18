import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    @Query(filter: #Predicate<Note> { $0.isPinned && !$0.isArchived }, sort: \Note.createdAt, order: .reverse)
    private var pinnedNotes: [Note]

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
                        }
                        .onDelete(perform: deleteProjects)
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
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredProjects[index])
        }
    }
}
