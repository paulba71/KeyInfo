import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @Binding var isUnlocked: Bool
    @State private var authError: String? = nil
    @State private var showingAlert = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var passcode = ""
    @State private var showingPasscodeEntry = false
    @AppStorage("useBiometricAuth") private var useBiometricAuth = true
    @AppStorage("requireAuthenticationOnLaunch") private var requireAuthenticationOnLaunch = true
    
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
                        if requireAuthenticationOnLaunch {
                            // Show authentication options only if required
                            if useBiometricAuth {
                                // FaceID/TouchID button
                                Button {
                                    authenticate()
                                } label: {
                                    HStack {
                                        Image(systemName: getBiometricIconName())
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
                        } else {
                            // Simple enter button when authentication is not required
                            Button {
                                isUnlocked = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Enter App")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .green],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(radius: 5)
                            }
                            
                            if useBiometricAuth {
                                // Optional biometric button for convenience
                                Button {
                                    authenticate()
                                } label: {
                                    HStack {
                                        Image(systemName: getBiometricIconName())
                                        Text("Quick Unlock")
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
                    if requireAuthenticationOnLaunch {
                        showingPasscodeEntry = true
                    }
                }
            } message: {
                Text(authError ?? "Please try again")
            }
        }
        .onAppear {
            // If authentication is required, attempt to authenticate
            if requireAuthenticationOnLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if useBiometricAuth {
                        authenticate()
                    } else {
                        // If biometric auth is disabled, show passcode screen
                        showingPasscodeEntry = true
                    }
                }
            }
            // Otherwise, just show the welcome screen with Enter App button
        }
    }
    
    private func getBiometricIconName() -> String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                return "lock.fill"
            }
        }
        
        return "lock.fill"
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