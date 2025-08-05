import SwiftUI

struct HabitSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var habits: [HabiticaHabit] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Loading habits...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                } else if habits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Daily Tasks Found")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create some daily recurring tasks in Habitica first, then come back here to select one to track.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Refresh") {
                            loadHabits()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(habits) { habit in
                        HabitRow(habit: habit) {
                            selectHabit(habit)
                        }
                    }
                }
            }
            .navigationTitle("Select Daily Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadHabits()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadHabits()
            }
        }
        
        if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
        }
    }
    
    private func loadHabits() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let fetchedHabits = try await dataManager.fetchAvailableHabits()
                await MainActor.run {
                    habits = fetchedHabits
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch data from Habitica: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func selectHabit(_ habit: HabiticaHabit) {
        let selectedHabit = SelectedHabit(id: habit.id, name: habit.displayName)
        dataManager.saveSelectedHabit(selectedHabit)
        
        // Refresh the habit data
        Task {
            try? await dataManager.refreshHabitData()
        }
        
        dismiss()
    }
}

struct HabitRow: View {
    let habit: HabiticaHabit
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if habit.completed == true {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("Pending", systemImage: "circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        if let streak = habit.streak, streak > 0 {
                            Label("\(streak) day streak", systemImage: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HabitSelectionView()
        .environmentObject(DataManager.shared)
}