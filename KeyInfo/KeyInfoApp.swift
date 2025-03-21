import SwiftUI
import SwiftData

@main
struct KeyInfoApp: App {
    let container: ModelContainer
    @State private var isUnlocked = false
    
    init() {
        do {
            // Configure SwiftData with optimized saving behavior
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
            container = try ModelContainer(for: KeyItem.self, configurations: configuration)
        } catch {
            fatalError("Failed to initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isUnlocked {
                ContentView()
                    .modelContainer(container)
            } else {
                AuthView(isUnlocked: $isUnlocked)
            }
        }
    }
} 