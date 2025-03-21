import SwiftUI
import SwiftData

@main
struct KeyInfoApp: App {
    let container: ModelContainer
    @State private var isUnlocked = false
    
    init() {
        do {
            container = try ModelContainer(for: KeyItem.self)
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