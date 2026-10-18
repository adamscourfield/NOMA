import Foundation
import SwiftData

@Model
final class NoteImage {
    @Attribute(.externalStorage)
    var data: Data
    var sortOrder: Int
    var note: Note?

    init(data: Data, sortOrder: Int = 0) {
        self.data = data
        self.sortOrder = sortOrder
    }
}
