import SwiftUI
import SwiftData

struct MoveNoteView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var moveError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(projects) { project in
                        Button {
                            move(to: project)
                        } label: {
                            HStack(spacing: 12) {
                                ProjectIconView(systemName: project.icon)
                                Text(project.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if note.project?.persistentModelID == project.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.coral)
                                        .accessibilityLabel("Current project")
                                }
                            }
                        }
                        .disabled(note.project?.persistentModelID == project.persistentModelID)
                    }
                } footer: {
                    if projects.count <= 1 {
                        Text("Create another project from Home to move this note there.")
                    } else {
                        Text("Choose a project. Your note, attachments, pin, and completion status will stay intact.")
                    }
                }
            }
            .navigationTitle("Move to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't move note", isPresented: Binding(
                get: { moveError != nil }, set: { if !$0 { moveError = nil } }
            )) {
                Button("OK", role: .cancel) { moveError = nil }
            } message: {
                Text(moveError ?? "")
            }
        }
    }

    private func move(to project: Project) {
        do {
            try note.move(to: project, in: modelContext)
            dismiss()
        } catch {
            moveError = error.localizedDescription
        }
    }
}
