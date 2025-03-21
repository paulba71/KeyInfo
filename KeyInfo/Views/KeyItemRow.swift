import SwiftUI

struct KeyItemRow: View {
    let item: KeyItem
    @Environment(\.colorScheme) private var colorScheme
    var onLikeToggle: (() -> Void)?
    
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
                    
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                }
                
                Text(item.value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
            }
            
            Button {
                onLikeToggle?()
            } label: {
                Image(systemName: item.isLikedSafe ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(item.isLikedSafe ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    KeyItemRow(
        item: KeyItem(label: "Test Item", value: "Test Value", iconName: "key.fill"),
        onLikeToggle: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
} 