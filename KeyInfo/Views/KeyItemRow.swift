import SwiftUI

struct KeyItemRow: View {
    let item: KeyItem
    @Environment(\.colorScheme) private var colorScheme
    var onLikeToggle: (() -> Void)?
    var onViewDetails: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row with icon, label and buttons
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(item.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if item.isLikedSafe {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                        
                        Text(item.label)
                            .font(.headline)
                        
                        Spacer()
                        
                        // Favorite toggle button
                        Button {
                            onLikeToggle?()
                        } label: {
                            Image(systemName: item.isLikedSafe ? "star.fill" : "star")
                                .foregroundStyle(item.isLikedSafe ? .yellow : .gray.opacity(0.5))
                        }
                        .buttonStyle(.borderless)
                        
                        // Details button
                        Button {
                            onViewDetails?()
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Value display - more prominent
            Text(item.value)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.color.opacity(0.2), lineWidth: 1)
                )
        }
        .contentShape(Rectangle()) // Make the entire row tappable
        .padding(.vertical, 6)
    }
}

#Preview {
    List {
        KeyItemRow(
            item: KeyItem(label: "Netflix Password", value: "SuperSecretPassword123", iconName: "lock.fill", category: "Entertainment", colorName: "red"),
            onLikeToggle: {},
            onViewDetails: {}
        )
        KeyItemRow(
            item: KeyItem(label: "Bank Account", value: "1234 5678 9012 3456", iconName: "creditcard.fill", category: "Finance", colorName: "green", isLiked: true),
            onLikeToggle: {},
            onViewDetails: {}
        )
        KeyItemRow(
            item: KeyItem(label: "Personal Email", value: "johndoe@example.com", iconName: "envelope.fill", category: "Personal", colorName: "blue"),
            onLikeToggle: {},
            onViewDetails: {}
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.light)
} 