import SwiftUI

struct ImageViewerView: View {
    let noteImage: NoteImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let uiImage = UIImage(data: noteImage.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
        .onTapGesture { dismiss() }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding()
            }
        }
    }
}
