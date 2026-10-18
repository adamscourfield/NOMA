import SwiftUI

struct ProjectRowView: View {
    @Bindable var project: Project

    private var activeCount: Int { project.activeNotes.count }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ProjectIconView(systemName: project.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name.isEmpty ? "Untitled Project" : project.name)
                        .font(.headline)
                        .fontDesign(.rounded)
                    Text(activeCount == 0 ? "All done" : "\(activeCount) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if activeCount > 0 {
                Text("\(activeCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Circle().fill(Color.coral))
            }
        }
        .padding(.vertical, 4)
    }
}
