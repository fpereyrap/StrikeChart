import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingLogin = false
    @State private var showingHabitSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if dataManager.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }
            }
            .navigationTitle("Strike Chart")
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
            .sheet(isPresented: $showingHabitSelection) {
                HabitSelectionView()
            }
        }
    }
    
    private var authenticatedContent: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Track Your Habits")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            // Current habit status
            if let selectedHabit = dataManager.selectedHabit {
                VStack(spacing: 12) {
                    Text("Current Habit")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(selectedHabit.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let habitData = dataManager.habitData {
                        ContributionGraphView(data: habitData)
                            .frame(height: 120)
                            .padding()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Select Habit") {
                    showingHabitSelection = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("Refresh Data") {
                    Task {
                        try? await dataManager.refreshHabitData()
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Logout") {
                    dataManager.clearCredentials()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text("Add the Strike Chart widget to your home screen to track your habit progress!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var unauthenticatedContent: some View {
        VStack(spacing: 30) {
            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Strike Chart")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("GitHub-style habit tracking for Habitica")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "square.grid.3x3.fill",
                    title: "Contribution Graph",
                    description: "See your habit progress in a beautiful grid"
                )
                
                FeatureRow(
                    icon: "iphone",
                    title: "Home Screen Widget",
                    description: "Track your habits right from your home screen"
                )
                
                FeatureRow(
                    icon: "link",
                    title: "Habitica Integration",
                    description: "Connects directly to your Habitica account"
                )
            }
            .padding()
            
            Spacer()
            
            // Login button
            Button("Connect to Habitica") {
                showingLogin = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .controlSize(.large)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}