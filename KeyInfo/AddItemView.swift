import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var label = ""
    @State private var value = ""
    @State private var selectedIcon = "doc.text.fill"
    
    let commonIcons = [
        "doc.text.fill",
        "creditcard.fill",
        "key.fill",
        "lock.fill",
        "person.text.rectangle.fill",
        "number.circle.fill",
        "house.fill",
        "car.fill",
        "briefcase.fill",
        "folder.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Label", text: $label)
                    TextField("Value", text: $value)
                }
                
                Section("Choose Icon") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(commonIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = KeyInfoItem(label: label, value: value, systemImage: selectedIcon)
                        modelContext.insert(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || value.isEmpty)
                }
            }
        }
    }
} 