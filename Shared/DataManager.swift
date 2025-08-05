import Foundation
import WidgetKit

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.yourname.StrikeChart")
    private let habiticaAPI = HabiticaAPI.shared
    
    // UserDefaults Keys
    private let selectedHabitKey = "selectedHabit"
    private let habitDataKey = "habitData"
    private let credentialsKey = "habiticaCredentials"
    
    @Published var selectedHabit: SelectedHabit?
    @Published var habitData: HabitWidgetData?
    @Published var isAuthenticated = false
    
    private init() {
        loadSelectedHabit()
        loadHabitData()
        checkAuthentication()
    }
    
    // MARK: - Authentication
    
    func saveCredentials(userId: String, apiToken: String) {
        let credentials = HabiticaCredentials(userId: userId, apiToken: apiToken)
        if let encoded = try? JSONEncoder().encode(credentials) {
            userDefaults?.set(encoded, forKey: credentialsKey)
            isAuthenticated = true
        }
    }
    
    func getCredentials() -> HabiticaCredentials? {
        guard let data = userDefaults?.data(forKey: credentialsKey),
              let credentials = try? JSONDecoder().decode(HabiticaCredentials.self, from: data) else {
            return nil
        }
        return credentials
    }
    
    func clearCredentials() {
        userDefaults?.removeObject(forKey: credentialsKey)
        isAuthenticated = false
    }
    
    private func checkAuthentication() {
        isAuthenticated = getCredentials() != nil
    }
    
    // MARK: - Habit Selection
    
    func saveSelectedHabit(_ habit: SelectedHabit) {
        selectedHabit = habit
        if let encoded = try? JSONEncoder().encode(habit) {
            userDefaults?.set(encoded, forKey: selectedHabitKey)
        }
        
        // Trigger widget refresh when habit selection changes
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitWidget")
        NSLog("🔄 DataManager: Triggered HabitWidget refresh after habit selection change")
    }
    
    private func loadSelectedHabit() {
        guard let data = userDefaults?.data(forKey: selectedHabitKey),
              let habit = try? JSONDecoder().decode(SelectedHabit.self, from: data) else {
            return
        }
        selectedHabit = habit
    }
    
    // MARK: - Habit Data
    
    func saveHabitData(_ data: HabitWidgetData) {
        habitData = data
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults?.set(encoded, forKey: habitDataKey)
        }
    }
    
    private func loadHabitData() {
        guard let data = userDefaults?.data(forKey: habitDataKey),
              let habitWidgetData = try? JSONDecoder().decode(HabitWidgetData.self, from: data) else {
            return
        }
        habitData = habitWidgetData
    }
    
    // MARK: - Data Refresh
    
    func refreshHabitData() async throws {
        guard let credentials = getCredentials(),
              let selectedHabit = selectedHabit else {
            throw DataManagerError.missingCredentials
        }
        
        // Fetch the specific habit and its history
        let habits = try await habiticaAPI.fetchHabits(
            userId: credentials.userId,
            apiToken: credentials.apiToken
        )
        
        guard let habit = habits.first(where: { $0.id == selectedHabit.id }) else {
            throw DataManagerError.habitNotFound
        }
        
        // Create realistic contribution graph based on habit data
        let widgetData = createRealisticHabitData(for: habit)
        saveHabitData(widgetData)
        
        // Force widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitWidget")
        NSLog("🔄 DataManager: Triggered HabitWidget refresh")
        
        NSLog("✅ DataManager: Successfully saved habit data for: \(habit.displayName)")
        NSLog("📊 DataManager: Habit type: \(habit.type), Completed: \(habit.completed ?? false), Streak: \(habit.streak ?? 0)")
        NSLog("💾 DataManager: Saved \(widgetData.completionData.count) days of data to UserDefaults")
        NSLog("🔍 DataManager: Widget data ID: \(widgetData.habitId), Name: '\(widgetData.habitName)'")
    }
    
    private func createRealisticHabitData(for habit: HabiticaHabit) -> HabitWidgetData {
        let calendar = Calendar.current
        let today = Date()
        let streak = habit.streak ?? 0
        let isCompleted = habit.completed ?? false
        
        // Create a realistic pattern based on habit data
        var completionData: [DayCompletion] = []
        
        for i in 0..<45 {
            guard let date = calendar.date(byAdding: .day, value: i - 44, to: today) else { continue }
            
            let dayIndex = i
            let isToday = dayIndex == 44
            
            // Create a realistic completion pattern
            var completed = false
            var count = 0
            
            // Since we only show daily tasks now, simplified logic for dailies only
            let isYesterday = dayIndex == 43
            
            // For dailies, be very conservative and realistic
            if streak > 0 {
                // If we have a streak, only show the most recent days
                // Since today is NOT completed (completed: false) but streak is 1,
                // this likely means yesterday was completed
                if isYesterday && streak >= 1 {
                    completed = true
                    count = 1
                } else if !isToday && !isYesterday && dayIndex >= (45 - streak + 1) {
                    // Show streak days going backwards from yesterday
                    completed = true
                    count = 1
                }
            }
            
            // Today's actual status
            if isToday {
                completed = isCompleted
                count = completed ? 1 : 0
            }
            
            completionData.append(DayCompletion(
                date: date,
                completed: completed,
                count: count
            ))
        }
        
        NSLog("🎯 DataManager: Generated 45-day completion data for daily task - Streak: \(streak), Today completed: \(isCompleted)")
        NSLog("🎯 DataManager: Completion pattern: \(completionData.map { $0.completed ? "✅" : "⬜" }.joined())")
        
        return HabitWidgetData(
            habitId: habit.id,
            habitName: "", // Empty for clean widget display
            completionData: completionData
        )
    }
    
    private func createSampleWidgetData(for habit: HabiticaHabit) -> HabitWidgetData {
        let calendar = Calendar.current
        let today = Date()
        
        let completionData = (0..<30).map { i in
            let date = calendar.date(byAdding: .day, value: i - 29, to: today) ?? today
            let completed = i % 3 != 0 // Show some completion pattern
            let count = completed ? Int.random(in: 1...3) : 0
            return DayCompletion(date: date, completed: completed, count: count)
        }
        
        return HabitWidgetData(
            habitId: habit.id,
            habitName: habit.displayName,
            completionData: completionData
        )
    }
    
    func fetchAvailableHabits() async throws -> [HabiticaHabit] {
        guard let credentials = getCredentials() else {
            throw DataManagerError.missingCredentials
        }
        
        let allHabits = try await habiticaAPI.fetchHabits(
            userId: credentials.userId,
            apiToken: credentials.apiToken
        )
        
        // Filter to only show daily recurring tasks
        let dailyHabits = allHabits.filter { $0.type == "daily" }
        
        NSLog("📋 DataManager: Filtered \(allHabits.count) total tasks to \(dailyHabits.count) daily tasks")
        
        return dailyHabits
    }
}

// MARK: - Supporting Models

struct HabiticaCredentials: Codable {
    let userId: String
    let apiToken: String
}

enum DataManagerError: Error, LocalizedError {
    case missingCredentials
    case habitNotFound
    case dataRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Habitica credentials not found. Please log in again."
        case .habitNotFound:
            return "Selected habit not found. Please select a different habit."
        case .dataRefreshFailed:
            return "Failed to refresh habit data."
        }
    }
}