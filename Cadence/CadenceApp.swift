import SwiftUI
import SwiftData

@main
struct CadenceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StatSnapshot.self,
            Idea.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
