import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // App Logo
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .padding(30)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Circle()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 4)
                            }
                        )
                        .shadow(radius: 10)
                    
                    VStack(spacing: 4) {
                        Text("KeyInfo")
                            .font(.largeTitle.weight(.bold))
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // About Content
                VStack(alignment: .leading, spacing: 24) {
                    infoSection(
                        title: "About KeyInfo",
                        content: "A secure app for storing and managing your important information, keys, codes, and personal details."
                    )
                    
                    infoSection(
                        title: "Security",
                        content: "Your data is securely stored on your device and protected with biometric authentication."
                    )
                    
                    VStack(alignment: .center, spacing: 16) {
                        Divider()
                            .padding(.horizontal)
                        
                        Text("Written by: Paul Barnes")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("© \(Calendar.current.component(.year, from: Date()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
} 