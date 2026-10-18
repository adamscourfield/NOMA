import SwiftUI
import SwiftData

@main
struct NOMAApp: App {
    @State private var isUnlocked = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Project.self, Note.self, NoteImage.self, NoteDocument.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isUnlocked {
                    HomeView()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                } else {
                    LockScreenView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            isUnlocked = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
