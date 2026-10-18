import SwiftUI
import SwiftData

struct EditProjectView: View {
    let project: Project
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedIcon: String
    @State private var showingDeleteConfirmation = false
    @State private var saveError: String?

    init(project: Project, onDelete: @escaping () -> Void) {
        self.project = project
        self.onDelete = onDelete
        _name = State(initialValue: project.name)
        _selectedIcon = State(initialValue: project.icon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project name", text: $name)
                        .accessibilityLabel("Project name")
                }
                Section("Icon") {
                    ProjectIconPicker(selectedIcon: $selectedIcon)
                }
                Section {
                    Button("Delete Project", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } footer: {
                    Text("Deleting a project also deletes all its active and archived notes, photos, audio, and documents.")
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Delete this project?", isPresented: $showingDeleteConfirmation) {
                Button("Delete Project", role: .destructive) {
                    // The presenting view deletes only after this sheet closes.
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("“\(project.name)” and all its active and archived notes, photos, audio, and documents will be permanently deleted. This cannot be undone.")
            }
            .alert("Couldn't save project", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let originalName = project.name
        let originalIcon = project.icon
        project.name = trimmed
        project.icon = selectedIcon
        do {
            try modelContext.save()
            dismiss()
        } catch {
            project.name = originalName
            project.icon = originalIcon
            saveError = error.localizedDescription
        }
    }
}

struct ProjectIconPicker: View {
    @Binding var selectedIcon: String
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(ProjectIcon.choices, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == icon ? Color.coral : Color.coral.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(selectedIcon == icon ? .white : Color.coral)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}
