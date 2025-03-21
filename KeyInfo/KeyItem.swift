import Foundation
import SwiftData
import SwiftUI

@Model
final class KeyItem {
    var label: String
    var value: String
    var iconName: String
    var dateCreated: Date
    var category: String
    var colorName: String
    var isLiked: Bool?
    
    init(label: String, value: String, iconName: String, category: String = "General", colorName: String = "blue", isLiked: Bool = false) {
        self.label = label
        self.value = value
        self.iconName = iconName
        self.dateCreated = Date()
        self.category = category
        self.colorName = colorName
        self.isLiked = isLiked
    }
    
    // Computed property to safely handle the optional isLiked value
    var isLikedSafe: Bool {
        return isLiked ?? false
    }
}

// Helper extension to get Color from string
extension KeyItem {
    var color: Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
} 