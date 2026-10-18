import Foundation
import SwiftData

@Model
final class NoteDocument {
    @Attribute(.externalStorage)
    var data: Data
    var fileName: String
    var fileExtension: String
    var sortOrder: Int
    var createdAt: Date
    var note: Note?

    init(data: Data, fileName: String, fileExtension: String, sortOrder: Int = 0) {
        self.data = data
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    // Audio uses the existing document entity: no new stored fields or schema migration.
    var isAudio: Bool {
        ["m4a", "mp3", "wav", "aif", "aiff", "caf", "aac"].contains(fileExtension.lowercased())
    }

    /// QuickLook previews from a file URL, not raw Data, so attached
    /// documents are written out to a scratch file on demand.
    func writeToTemporaryURL() -> URL? {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = directory.appendingPathComponent("\(fileName).\(fileExtension)")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
