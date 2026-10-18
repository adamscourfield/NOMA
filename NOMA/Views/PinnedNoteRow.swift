import SwiftUI

struct PinnedNoteRow: View {
    @Bindable var note: Note

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.coral)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let projectName = note.project?.name, !projectName.isEmpty {
                    Text(projectName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.coral)
                        .tracking(0.5)
                }
            }

            Spacer()

            Image(systemName: "pin.fill")
                .font(.caption2)
                .foregroundStyle(Color.coral)
        }
        .padding(.vertical, 2)
    }
}
