import SwiftUI

struct NoteRowView: View {
    @Bindable var note: Note
    var isCompleting: Bool = false
    var onToggle: () -> Void

    private var thumbnail: UIImage? {
        guard let first = note.sortedImages.first else { return nil }
        return UIImage(data: first.data)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isCompleting ? Color.coral : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isCompleting)
            .padding(.top, 2)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.coral)
                    }
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                }
                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 10) {
                    if !note.sortedAudio.isEmpty {
                        Label("\(note.sortedAudio.count)", systemImage: "waveform")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if !note.sortedDocuments.isEmpty {
                        Label("\(note.sortedDocuments.count)", systemImage: "paperclip")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
