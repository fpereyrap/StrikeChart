import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var loginMethod: LoginMethod = .credentials
    @State private var username = ""
    @State private var password = ""
    @State private var userId = ""
    @State private var apiToken = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    enum LoginMethod: String, CaseIterable {
        case credentials = "Username & Password"
        case apiTokens = "API Tokens"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Connect to Habitica")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Enter your Habitica credentials to sync your habits")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Login method selector
                    Picker("Login Method", selection: $loginMethod) {
                        ForEach(LoginMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Form
                    VStack(spacing: 20) {
                        if loginMethod == .credentials {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username or Email")
                                    .font(.headline)
                                
                                TextField("Enter your username or email", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("User ID")
                                    .font(.headline)
                                
                                TextField("Enter your User ID", text: $userId)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Token")
                                    .font(.headline)
                                
                                SecureField("Enter your API Token", text: $apiToken)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                        }
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        if loginMethod == .credentials {
                            Text("Use your Habitica login credentials:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Use the same username/email and password you use on habitica.com")
                                Text("• This is the easiest and most secure method")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        } else {
                            Text("How to find your API credentials:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. Go to habitica.com and log in")
                                Text("2. Go to Settings → API")
                                Text("3. Copy your User ID and API Token")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Spacer(minLength: 20)
                    
                    // Login button
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Connect")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                    .disabled(!isFormValid() || isLoading)
                }
                .padding()
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        if loginMethod == .credentials {
            return !username.isEmpty && !password.isEmpty
        } else {
            return !userId.isEmpty && !apiToken.isEmpty
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if loginMethod == .credentials {
                    // Login with username/password
                    let loginResponse = try await HabiticaAPI.shared.login(
                        username: username,
                        password: password
                    )
                    
                    await MainActor.run {
                        dataManager.saveCredentials(userId: loginResponse.id, apiToken: loginResponse.apiToken)
                        dismiss()
                    }
                } else {
                    // Authenticate with existing API tokens
                    let _ = try await HabiticaAPI.shared.authenticate(
                        userId: userId,
                        apiToken: apiToken
                    )
                    
                    await MainActor.run {
                        dataManager.saveCredentials(userId: userId, apiToken: apiToken)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(DataManager.shared)
}