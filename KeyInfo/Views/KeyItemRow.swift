import SwiftUI

struct KeyItemRow: View {
    let item: KeyItem
    @Environment(\.colorScheme) private var colorScheme
    var onLikeToggle: (() -> Void)?
    var onViewDetails: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(item.color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
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
                
                HStack {
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(item.value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(Rectangle()) // Make the entire row tappable
        .padding(.vertical, 4)
    }
}

#Preview {
    KeyItemRow(
        item: KeyItem(label: "Test Item", value: "Test Value", iconName: "key.fill"),
        onLikeToggle: {},
        onViewDetails: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
} 