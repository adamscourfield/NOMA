import SwiftUI

struct DocumentRowView: View {
    let document: NoteDocument

    private var systemImageName: String {
        switch document.fileExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "jpg", "jpeg", "png", "heic": return "photo"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx", "csv": return "tablecells"
        case "ppt", "pptx": return "rectangle.on.rectangle"
        default: return "doc"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImageName)
                .font(.system(size: 18))
                .foregroundStyle(Color.coral)
                .frame(width: 32, height: 32)
                .background(Color.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(document.fileName).\(document.fileExtension)")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: Int64(document.data.count), countStyle: .file))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
