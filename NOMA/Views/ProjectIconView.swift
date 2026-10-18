import SwiftUI

/// The curated set a project's icon is chosen from, shared by the picker and
/// by anything rendering a project's icon chip.
enum ProjectIcon {
    static let choices = [
        "folder", "briefcase", "wrench.and.screwdriver", "house",
        "sun.max", "airplane", "cart", "book", "heart", "star"
    ]
}

struct ProjectIconView: View {
    let systemName: String
    var size: CGFloat = 36

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Color.coral.opacity(0.12))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(Color.coral)
            }
    }
}
