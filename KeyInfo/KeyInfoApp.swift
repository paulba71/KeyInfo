import SwiftUI
import SwiftData

@main
struct KeyInfoApp: App {
    let container: ModelContainer
    @State private var isUnlocked = false
    
    init() {
        do {
            // Configure SwiftData with enhanced migration options
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
            
            // First try to create the container normally
            do {
                container = try ModelContainer(for: KeyItem.self, configurations: configuration)
            } catch {
                // If normal initialization fails, we'll try with destructive migration
                print("Normal container initialization failed: \(error.localizedDescription)")
                print("Attempting destructive migration...")
                
                // Get the default store URL
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                
                // Try to delete the existing store files
                let fileManager = FileManager.default
                try? fileManager.removeItem(at: url)
                try? fileManager.removeItem(at: url.appendingPathExtension("sqlite-shm"))
                try? fileManager.removeItem(at: url.appendingPathExtension("sqlite-wal"))
                
                // Try again with a fresh store
                container = try ModelContainer(for: KeyItem.self, configurations: configuration)
                print("Destructive migration successful")
            }
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
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