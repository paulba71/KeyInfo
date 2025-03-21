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
    
    init(item: KeyItem, onDelete: @escaping () -> Void, startEditing: Bool = false) {
        self.item = item
        self.onDelete = onDelete
        _editedLabel = State(initialValue: item.label)
        _editedValue = State(initialValue: item.value)
        _editedCategory = State(initialValue: item.category)
        _editedColorName = State(initialValue: item.colorName)
        _isEditing = State(initialValue: startEditing)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Icon header
                ZStack {
                    Circle()
                        .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(item.color)
                }
                .padding(.top, 20)
                
                // Content
                VStack(spacing: 30) {
                    if isEditing {
                        editingView
                    } else {
                        displayView
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
        }
        .navigationTitle(isEditing ? "Edit Item" : item.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                } else {
                    Menu {
                        Button(action: { isEditing = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                        // Reset edited values
                        editedLabel = item.label
                        editedValue = item.value
                        editedCategory = item.category
                        editedColorName = item.colorName
                    }
                }
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
    
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 24) {
            infoRow(title: "Label", value: item.label, iconName: "tag")
            
            VStack(alignment: .leading) {
                HStack {
                    Label("Value", systemImage: "doc.text")
                        .font(.headline)
                    Spacer()
                    Button(action: copyValueToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(item.value)
                    .padding(.top, 4)
                    .textSelection(.enabled)
                    .overlay(alignment: .trailing) {
                        if showCopiedMessage {
                            Text("Copied!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(UIColor.tertiarySystemBackground))
                                )
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
            }
            
            infoRow(title: "Category", value: item.category, iconName: "folder")
            
            infoRow(title: "Date Added", value: item.dateCreated.formatted(date: .abbreviated, time: .shortened), iconName: "calendar")
        }
    }
    
    private var editingView: some View {
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
    
    private func infoRow(title: String, value: String, iconName: String) -> some View {
        VStack(alignment: .leading) {
            Label(title, systemImage: iconName)
                .font(.headline)
            
            Text(value)
                .padding(.top, 4)
        }
    }
    
    private func copyValueToClipboard() {
        UIPasteboard.general.string = item.value
        
        withAnimation {
            showCopiedMessage = true
        }
        
        // Hide the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
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