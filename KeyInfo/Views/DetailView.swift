import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var editedLabel: String
    @State private var editedValue: String
    @State private var editedCategory: String
    @State private var editedColorName: String
    @State private var showCopiedMessage = false
    
    let item: KeyItem
    var onDelete: () -> Void
    var isReadOnly: Bool
    
    init(item: KeyItem, onDelete: @escaping () -> Void, startEditing: Bool = false, isReadOnly: Bool = false) {
        self.item = item
        self.onDelete = onDelete
        self.isReadOnly = isReadOnly
        _editedLabel = State(initialValue: item.label)
        _editedValue = State(initialValue: item.value)
        _editedCategory = State(initialValue: item.category)
        _editedColorName = State(initialValue: item.colorName)
        _isEditing = State(initialValue: startEditing && !isReadOnly)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Icon header
                ZStack {
                    Circle()
                        .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(item.color)
                }
                .padding(.top)
                
                // Content
                VStack(spacing: 25) {
                    if isEditing {
                        // Edit mode
                        editForm
                    } else {
                        // View mode
                        detailsCard
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle(isEditing ? "Edit Item" : "Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if !isReadOnly {
                            if isEditing {
                                Button("Cancel") {
                                    isEditing = false
                                    resetEditedValues()
                                }
                                
                                Button("Save") {
                                    saveChanges()
                                    isEditing = false
                                }
                                .bold()
                            } else {
                                Button("Edit") {
                                    isEditing = true
                                }
                                
                                Menu {
                                    Button(role: .destructive) {
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        } else {
                            // Read-only mode - show copy option
                            Button {
                                UIPasteboard.general.string = item.value
                                withAnimation {
                                    showCopiedMessage = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showCopiedMessage = false
                                    }
                                }
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            
                            if !isEditing {
                                Button {
                                    isEditing = true
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .disabled(isReadOnly)
                            }
                        }
                    }
                }
            }
            .overlay(
                // Copy confirmation toast
                Group {
                    if showCopiedMessage {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Copied to clipboard")
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                            .padding(.bottom, 20)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .alert("Delete Item?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    dismiss()
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
        }
    }
    
    // Read-only details card
    private var detailsCard: some View {
        VStack(spacing: 20) {
            detailRow(title: "Label", value: item.label, systemImage: "tag")
            
            detailRow(title: "Value", value: item.value, systemImage: "doc.text", isCopyable: true)
            
            detailRow(title: "Category", value: item.category, systemImage: "folder")
            
            detailRow(
                title: "Created",
                value: item.dateCreated.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )
            
            if item.isLikedSafe {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Favorite")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
    
    private func detailRow(title: String, value: String, systemImage: String, isCopyable: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                
                Spacer()
                
                if isCopyable {
                    Button {
                        UIPasteboard.general.string = value
                        withAnimation {
                            showCopiedMessage = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopiedMessage = false
                            }
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Text(value)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
    
    // Edit form
    private var editForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Label")
                    .font(.headline)
                TextField("Label", text: $editedLabel)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Value")
                    .font(.headline)
                TextField("Value", text: $editedValue)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Category")
                    .font(.headline)
                TextField("Category", text: $editedCategory)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Color")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["blue", "red", "green", "orange", "purple", "teal", "pink", "yellow", "indigo", "mint", "cyan", "brown"], id: \.self) { color in
                            colorButton(color)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func colorButton(_ colorName: String) -> some View {
        let isSelected = editedColorName == colorName
        
        return Button {
            editedColorName = colorName
        } label: {
            ZStack {
                Circle()
                    .fill(KeyItem(label: "", value: "", iconName: "", colorName: colorName).color)
                    .frame(width: 30, height: 30)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
    
    private func resetEditedValues() {
        editedLabel = item.label
        editedValue = item.value
        editedCategory = item.category
        editedColorName = item.colorName
    }
    
    private func saveChanges() {
        item.label = editedLabel
        item.value = editedValue
        item.category = editedCategory
        item.colorName = editedColorName
        
        // Explicitly save changes to ensure persistence
        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
        
        isEditing = false
    }
}

#Preview {
    NavigationStack {
        DetailView(
            item: KeyItem(label: "Test Item", value: "Test Value", iconName: "key.fill"),
            onDelete: {}
        )
    }
} 