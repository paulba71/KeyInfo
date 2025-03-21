import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @Binding var isUnlocked: Bool
    @State private var authError: String? = nil
    @State private var showingAlert = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var passcode = ""
    @State private var showingPasscodeEntry = false
    
    // Simple passcode for development/simulator use
    private let developerPasscode = "1234"
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(colorScheme == .dark ? 0.6 : 0.3), .indigo.opacity(colorScheme == .dark ? 0.3 : 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(30)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(radius: 10)
                
                // App title and description
                VStack(spacing: 16) {
                    Text("KeyInfo")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Your secure key information manager")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                if showingPasscodeEntry {
                    // Passcode entry view
                    VStack(spacing: 20) {
                        Text("Enter Passcode")
                            .font(.headline)
                        
                        SecureField("Passcode", text: $passcode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                            .padding()
                        
                        Button("Unlock") {
                            checkPasscode()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                } else {
                    // Unlock buttons
                    VStack(spacing: 15) {
                        // FaceID/TouchID button
                        Button {
                            authenticate()
                        } label: {
                            HStack {
                                Image(systemName: "faceid")
                                Text("Unlock with Biometrics")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .indigo],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(radius: 5)
                        }
                        
                        // Passcode button
                        Button {
                            showingPasscodeEntry = true
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Use Passcode")
                            }
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                            )
                            .shadow(radius: 3)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .padding()
            .alert("Authentication Failed", isPresented: $showingAlert) {
                Button("OK") { 
                    // Show passcode entry after biometric failure
                    showingPasscodeEntry = true
                }
            } message: {
                Text(authError ?? "Please try again")
            }
        }
        .onAppear {
            // Automatically attempt authentication when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Set the reason for authentication
            let reason = "Unlock KeyInfo to access your secure information"
            
            // Perform biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        // Handle authentication error
                        if let error = authenticationError {
                            self.authError = error.localizedDescription
                            self.showingAlert = true
                        }
                    }
                }
            }
        } else {
            // Fallback if biometrics are not available
            self.authError = "Biometric authentication is not available on this device."
            self.showingAlert = true
        }
    }
    
    private func checkPasscode() {
        if passcode == developerPasscode {
            isUnlocked = true
        } else {
            passcode = ""
            authError = "Incorrect passcode. Please try again."
            showingAlert = true
        }
    }
}

#Preview {
    AuthView(isUnlocked: .constant(false))
} 