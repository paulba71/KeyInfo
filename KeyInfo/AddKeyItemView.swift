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
    @State private var isCustomLabel = false
    
    // Predefined categories
    let categories = ["General", "Personal", "Financial", "Work", "Home", "Travel", "Security"]
    
    enum ItemType: String, CaseIterable {
        case license = "Driver License"
        case pps = "PPS Number"
        case eircode = "Eircode"
        case postcode = "Postcode"
        case zipcode = "Zipcode"
        case locker = "Locker Code"
        case passport = "Passport Number"
        case ssn = "Social Security Number"
        case ni = "National Insurance Number"
        case pin = "PIN Code"
        case bankAccount = "Bank Account"
        case creditCard = "Credit Card"
        case wifi = "WiFi Password"
        case email = "Email Account"
        case username = "Username"
        case phone = "Phone Number"
        case blood = "Blood Type"
        case medical = "Medical Number"
        case gpPhone = "GP Phone Number"
        case studentID = "Student ID"
        case insurance = "Insurance"
        case membership = "Membership Number"
        case petLicense = "Pet License Number"
        case carReg = "Car Registration"
        case generic = "Generic"
        case custom = "Custom"
        
        var iconName: String {
            switch self {
            case .license: return "car.fill"
            case .pps: return "person.text.rectangle.fill"
            case .eircode, .postcode, .zipcode: return "house.fill"
            case .locker, .pin: return "lock.fill"
            case .passport: return "airplane"
            case .ssn, .ni: return "person.badge.key.fill"
            case .bankAccount: return "banknote.fill"
            case .creditCard: return "creditcard.fill"
            case .wifi: return "wifi"
            case .email: return "envelope.fill"
            case .username: return "person.crop.circle.fill"
            case .phone, .gpPhone: return "phone.fill"
            case .blood: return "drop.fill"
            case .medical: return "cross.case.fill"
            case .studentID: return "graduationcap.fill"
            case .insurance: return "checkmark.shield.fill"
            case .membership: return "person.2.fill"
            case .petLicense: return "pawprint.fill"
            case .carReg: return "car.2.fill"
            case .generic: return "questionmark.app.fill"
            case .custom: return "doc.fill"
            }
        }
        
        var suggestedCategory: String {
            switch self {
            case .license, .pps, .passport, .ssn, .ni, .studentID: return "Personal"
            case .bankAccount, .creditCard, .insurance: return "Financial"
            case .eircode, .postcode, .zipcode, .wifi: return "Home"
            case .locker, .pin: return "Security"
            case .email, .phone, .username, .gpPhone: return "Contact"
            case .blood, .medical: return "Medical"
            case .membership: return "Membership"
            case .petLicense: return "Pets"
            case .carReg: return "Vehicle"
            case .generic: return "Other"
            default: return "General"
            }
        }
        
        var suggestedColor: String {
            switch self {
            case .license, .pps, .passport, .ssn, .ni, .studentID: return "blue"
            case .bankAccount, .creditCard: return "green"
            case .eircode, .postcode, .zipcode, .wifi: return "orange"
            case .locker, .pin, .insurance: return "red"
            case .email, .phone, .username, .gpPhone: return "teal"
            case .blood, .medical: return "pink"
            case .membership: return "purple"
            case .petLicense: return "brown"
            case .carReg: return "indigo"
            case .generic: return "mint"
            default: return "blue"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ItemType.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedType) {
                        if !isCustomLabel {
                            label = selectedType.rawValue
                        }
                        category = selectedType.suggestedCategory
                        selectedColor = selectedType.suggestedColor
                    }
                }
                
                Section("Details") {
                    TextField("Label", text: $label)
                        .onChange(of: label) {
                            isCustomLabel = label != selectedType.rawValue
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
        case .eircode, .postcode, .zipcode: return .postalCode
        case .passport: return .username
        case .ssn, .ni, .medical, .studentID, .petLicense: return .username
        case .bankAccount: return .username
        case .creditCard: return .creditCardNumber
        case .wifi: return .password
        case .email: return .emailAddress
        case .username: return .username
        case .phone, .gpPhone: return .telephoneNumber
        case .pin: return .password
        case .blood: return nil
        case .insurance: return .username 
        case .membership: return .username
        default: return nil
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch selectedType {
        case .phone, .gpPhone: return .phonePad
        case .eircode, .postcode, .zipcode: return .asciiCapable
        case .email: return .emailAddress
        case .creditCard: return .numberPad
        case .locker, .pin: return .numberPad
        case .ssn, .ni, .medical, .studentID, .membership, .petLicense: return .default
        case .blood: return .default
        case .bankAccount: return .numbersAndPunctuation
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
        
        // Explicitly save changes to ensure persistence
        do {
            try modelContext.save()
        } catch {
            print("Error saving item: \(error.localizedDescription)")
        }
        
        dismiss()
    }
} 