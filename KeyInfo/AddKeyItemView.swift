import SwiftUI
import SwiftData

struct AddKeyItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var label = ""
    @State private var value = ""
    @State private var selectedType = ItemType.custom
    @State private var category = "General"
    @State private var selectedColor = "blue"
    @State private var showingAdvancedOptions = false
    
    // Predefined categories
    let categories = ["General", "Personal", "Financial", "Work", "Home", "Travel", "Security"]
    
    enum ItemType: String, CaseIterable {
        case license = "Driver License"
        case pps = "PPS Number"
        case eircode = "Eircode"
        case locker = "Locker Code"
        case passport = "Passport"
        case bankAccount = "Bank Account"
        case creditCard = "Credit Card"
        case wifi = "WiFi Password"
        case email = "Email Account"
        case phone = "Phone Number"
        case insurance = "Insurance"
        case membership = "Membership"
        case custom = "Custom"
        
        var iconName: String {
            switch self {
            case .license: return "car.fill"
            case .pps: return "person.text.rectangle.fill"
            case .eircode: return "house.fill"
            case .locker: return "lock.fill"
            case .passport: return "airplane"
            case .bankAccount: return "banknote.fill"
            case .creditCard: return "creditcard.fill"
            case .wifi: return "wifi"
            case .email: return "envelope.fill"
            case .phone: return "phone.fill"
            case .insurance: return "checkmark.shield.fill"
            case .membership: return "person.2.fill"
            case .custom: return "doc.fill"
            }
        }
        
        var suggestedCategory: String {
            switch self {
            case .license, .pps, .passport: return "Personal"
            case .bankAccount, .creditCard, .insurance: return "Financial"
            case .eircode, .wifi: return "Home"
            case .locker: return "Security"
            case .email, .phone: return "Contact"
            case .membership: return "Membership"
            default: return "General"
            }
        }
        
        var suggestedColor: String {
            switch self {
            case .license, .pps, .passport: return "blue"
            case .bankAccount, .creditCard: return "green"
            case .eircode, .wifi: return "orange"
            case .locker, .insurance: return "red"
            case .email, .phone: return "teal"
            case .membership: return "purple"
            default: return "blue"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedType) {
                        if selectedType != .custom {
                            label = selectedType.rawValue
                            category = selectedType.suggestedCategory
                            selectedColor = selectedType.suggestedColor
                        }
                    }
                }
                
                Section("Details") {
                    if selectedType == .custom {
                        TextField("Label", text: $label)
                    }
                    
                    TextField("Value", text: $value)
                        .textContentType(contentType)
                        .keyboardType(keyboardType)
                }
                
                DisclosureGroup("Advanced Options", isExpanded: $showingAdvancedOptions) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["blue", "red", "green", "orange", "purple", "teal", "pink", "yellow", "indigo", "mint", "cyan", "brown"], id: \.self) { color in
                                    colorButton(color)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Add Key Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addItem()
                    }
                    .disabled(label.isEmpty || value.isEmpty)
                }
            }
        }
    }
    
    private var contentType: UITextContentType? {
        switch selectedType {
        case .license: return .username
        case .pps: return .username
        case .eircode: return .postalCode
        case .passport: return .username
        case .bankAccount: return .username
        case .creditCard: return .creditCardNumber
        case .wifi: return .password
        case .email: return .emailAddress
        case .phone: return .telephoneNumber
        case .insurance: return .username
        case .membership: return .username
        default: return nil
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch selectedType {
        case .phone: return .phonePad
        case .eircode: return .asciiCapable
        case .email: return .emailAddress
        case .creditCard: return .numberPad
        case .locker: return .numberPad
        default: return .default
        }
    }
    
    private func colorButton(_ colorName: String) -> some View {
        let isSelected = selectedColor == colorName
        
        return Button {
            selectedColor = colorName
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
    
    private func addItem() {
        let item = KeyItem(
            label: label,
            value: value,
            iconName: selectedType.iconName,
            category: category,
            colorName: selectedColor
        )
        modelContext.insert(item)
        dismiss()
    }
} 