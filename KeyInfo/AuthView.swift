import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @Binding var isUnlocked: Bool
    @State private var showingBiometricError = false
    @State private var errorMessage = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Animated background
            gradient
                .opacity(colorScheme == .dark ? 0.8 : 0.3)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(gradient)
                }
                .padding(.bottom, 20)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("KeyInfo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your personal information vault")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Unlock button
                Button(action: authenticate) {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .font(.title2)
                        Text("Unlock App")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .alert("Authentication Error", isPresented: $showingBiometricError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock KeyInfo to access your personal information") { success, authError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring) {
                            isUnlocked = true
                        }
                    } else {
                        errorMessage = authError?.localizedDescription ?? "Authentication failed"
                        showingBiometricError = true
                    }
                }
            }
        } else {
            errorMessage = error?.localizedDescription ?? "Device does not support biometric authentication"
            showingBiometricError = true
        }
    }
} 