import Foundation
import SwiftData

@Model
final class KeyInfoItem: Identifiable {
    let id: UUID
    var label: String
    var value: String
    var systemImage: String
    var dateCreated: Date
    
    init(label: String, value: String, systemImage: String) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.systemImage = systemImage
        self.dateCreated = Date()
    }
} 