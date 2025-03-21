import SwiftUI
import LocalAuthentication
import SwiftData

struct SettingsView: View {
    @AppStorage("useBiometricAuth") private var useBiometricAuth = true
    @AppStorage("requireAuthenticationOnLaunch") private var requireAuthenticationOnLaunch = true
    @State private var biometricsAvailable = false
    @State private var biometricType = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [KeyItem]
    
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteAllConfirmationAlert = false
    @State private var deleteConfirmationText = ""
    @State private var showingSampleDataAlert = false
    @State private var sampleDataAdded = false
    
    // Importing necessary types from AddKeyItemView
    enum DataItemType {
        case email, password, creditCard, passport, ssn, bankAccount, pinCode, carRegistration
        
        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .password: return "lock.fill"
            case .creditCard: return "creditcard.fill"
            case .passport: return "airplane"
            case .ssn: return "person.badge.key.fill"
            case .bankAccount: return "banknote.fill"
            case .pinCode: return "lock.square.fill"
            case .carRegistration: return "car.fill"
            }
        }
        
        var color: String {
            switch self {
            case .email: return "blue"
            case .password: return "purple"
            case .creditCard: return "green"
            case .passport: return "indigo"
            case .ssn: return "red"
            case .bankAccount: return "teal"
            case .pinCode: return "orange"
            case .carRegistration: return "indigo"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    if biometricsAvailable {
                        Toggle("Use \(biometricType) Authentication", isOn: $useBiometricAuth)
                            .onChange(of: useBiometricAuth) { _, newValue in
                                // If biometrics is disabled, make sure requireAuth is still true
                                // to ensure passcode is still required
                                if !newValue {
                                    requireAuthenticationOnLaunch = true
                                }
                            }
                    } else {
                        Text("Biometric authentication is not available on this device")
                            .foregroundStyle(.secondary)
                    }
                    
                    Toggle("Require Authentication on Launch", isOn: $requireAuthenticationOnLaunch)
                        .disabled(!useBiometricAuth && !requireAuthenticationOnLaunch)
                        // Prevent turning off all auth if biometrics is off
                }
                
                Section(header: Text("Data Management")) {
                    Button("Generate Sample Data") {
                        showingSampleDataAlert = true
                    }
                    .foregroundStyle(.blue)
                    
                    Button("Delete All Data", role: .destructive) {
                        showingDeleteAllAlert = true
                    }
                    .foregroundStyle(.red)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkBiometricAvailability()
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteAllConfirmationAlert = true
                }
            } message: {
                Text("This will permanently delete all your stored information. This action cannot be undone.")
            }
            .alert("Confirm Deletion", isPresented: $showingDeleteAllConfirmationAlert) {
                TextField("Type 'delete' to confirm", text: $deleteConfirmationText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                
                Button("Delete Everything", role: .destructive) {
                    if deleteConfirmationText.lowercased() == "delete" {
                        deleteAllData()
                    }
                    deleteConfirmationText = ""
                }
                .disabled(deleteConfirmationText.lowercased() != "delete")
                
            } message: {
                Text("To confirm deletion of all data, type 'delete' below.")
            }
            .alert("Generate Sample Data", isPresented: $showingSampleDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Add Sample Data") {
                    generateSampleData()
                    sampleDataAdded = true
                }
            } message: {
                Text("This will add 10 sample entries to help you see how the app works with data. Continue?")
            }
            .alert("Sample Data Added", isPresented: $sampleDataAdded) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("10 sample entries have been added to the app. You can now explore the app with sample data.")
            }
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if biometricsAvailable {
            switch context.biometryType {
            case .faceID:
                biometricType = "Face ID"
            case .touchID:
                biometricType = "Touch ID"
            default:
                biometricType = "Biometric"
            }
        }
    }
    
    private func resetSettings() {
        // Reset settings to default values
        useBiometricAuth = true
        requireAuthenticationOnLaunch = true
    }
    
    private func deleteAllData() {
        // Delete all items from the database
        for item in items {
            modelContext.delete(item)
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete data: \(error.localizedDescription)")
        }
    }
    
    private func generateSampleData() {
        // Sample items with variety of types, categories, and values
        let sampleItems: [(String, DataItemType, String, String, Bool)] = [
            ("Personal Email", .email, "Personal", "johndoe@example.com", true),
            ("Work Email", .email, "Work", "john.doe@company.com", false),
            ("Home WiFi Password", .password, "Home", "HomeWifi2023!", false),
            ("Netflix Account", .password, "Entertainment", "NetflixPass123", false),
            ("Credit Card", .creditCard, "Finance", "1234 5678 9012 3456", true),
            ("Passport Number", .passport, "Travel", "AB123456", false),
            ("Social Security", .ssn, "Personal", "123-45-6789", false),
            ("Bank Account", .bankAccount, "Finance", "987654321", false),
            ("Office Door Code", .pinCode, "Work", "4513", false),
            ("Car Registration", .carRegistration, "Vehicle", "ABC123XYZ", false)
        ]
        
        // Create items with specified values
        for (index, (label, type, category, value, isLiked)) in sampleItems.enumerated() {
            let item = KeyItem(
                label: label,
                value: value, 
                iconName: type.icon,
                category: category,
                colorName: type.color,
                isLiked: isLiked
            )
            
            // Set creation date to be slightly different for each item
            // Older items first, more recent items last
            item.dateCreated = Date().addingTimeInterval(-Double(10 - index) * 86400)
            
            // Add to model context
            modelContext.insert(item)
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save sample data: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
}
