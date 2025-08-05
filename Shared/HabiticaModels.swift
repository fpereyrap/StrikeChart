import Foundation

// MARK: - Habitica API Models

struct HabiticaUser: Codable {
    let id: String
    let auth: HabiticaAuth
    let profile: HabiticaProfile
    
    struct HabiticaAuth: Codable {
        let apiToken: String
        let userId: String
    }
    
    struct HabiticaProfile: Codable {
        let name: String
    }
}

struct HabiticaLoginRequest: Codable {
    let username: String
    let password: String
}

struct HabiticaLoginResponse: Codable {
    let id: String
    let apiToken: String
    let newUser: Bool
}

struct HabiticaHabit: Codable, Identifiable {
    let id: String
    let text: String
    let type: String
    let completed: Bool?
    let streak: Int?
    let isDue: Bool?
    
    // Custom CodingKeys to map _id to id and only include essential fields
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text, type, completed, streak, isDue
    }
    
    var displayName: String {
        text.isEmpty ? "Unnamed Habit" : text
    }
    
    var isDaily: Bool {
        return type == "daily"
    }
    
    var isCompleted: Bool {
        return completed ?? false
    }
}

struct HabiticaHistoryEntry: Codable {
    let date: String
    let value: Double
    
    var dateFormatted: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

struct HabiticaResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let message: String?
}

// MARK: - Widget Data Models

struct HabitWidgetData: Codable {
    let habitId: String
    let habitName: String
    let completionData: [DayCompletion]
    let lastUpdated: Date
    
    init(habitId: String, habitName: String, completionData: [DayCompletion]) {
        self.habitId = habitId
        self.habitName = habitName
        self.completionData = completionData
        self.lastUpdated = Date()
    }
}

struct DayCompletion: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let completed: Bool
    let count: Int // For habits that can be done multiple times per day
    
    init(date: Date, completed: Bool, count: Int = 0) {
        self.date = date
        self.completed = completed
        self.count = count
    }
}

// MARK: - Configuration Models

struct SelectedHabit: Codable {
    let id: String
    let name: String
    let lastUpdated: Date
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.lastUpdated = Date()
    }
}

// MARK: - Helper Extensions

extension Date {
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    static func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date().startOfDay()) ?? Date()
    }
}