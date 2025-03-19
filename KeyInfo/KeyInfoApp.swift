import SwiftUI
import SwiftData

@main
struct KeyInfoApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: KeyInfoItem.self)
        } catch {
            fatalError("Failed to initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
} 