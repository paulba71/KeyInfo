import SwiftUI

struct KeyItemRowWithActions: View {
    let item: KeyItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onLikeToggle: () -> Void
    
    var body: some View {
        Button {
            onCopy()
        } label: {
            KeyItemRow(item: item, onLikeToggle: onLikeToggle)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            
            Button {
                onLikeToggle()
            } label: {
                Label((item.isLikedSafe) ? "Unlike" : "Like", systemImage: (item.isLikedSafe) ? "star.slash" : "star")
            }
            
            NavigationLink {
                DetailView(item: item, onDelete: onDelete, startEditing: true)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            NavigationLink {
                DetailView(item: item, onDelete: onDelete, startEditing: true)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            Button {
                onLikeToggle()
            } label: {
                Label((item.isLikedSafe) ? "Unlike" : "Like", systemImage: (item.isLikedSafe) ? "star.slash" : "star")
            }
            .tint(.yellow)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            KeyItemRowWithActions(
                item: KeyItem(label: "Test Item", value: "Test Value", iconName: "key.fill"),
                onCopy: {},
                onDelete: {},
                onLikeToggle: {}
            )
        }
    }
} 