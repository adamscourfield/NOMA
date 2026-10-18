import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = ProjectIcon.choices[0]
    @FocusState private var nameFieldFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project name", text: $name)
                        .focused($nameFieldFocused)
                }

                Section("Icon") {
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
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createProject)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameFieldFocused = true }
        }
    }

    private func createProject() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let project = Project(name: trimmed, icon: selectedIcon)
        modelContext.insert(project)
        dismiss()
    }
}
