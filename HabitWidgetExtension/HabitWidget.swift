import WidgetKit
import SwiftUI

// MARK: - Helper Functions
func createSampleHabitData() -> HabitWidgetData {
    return HabitWidgetData(
        habitId: "sample",
        habitName: "", // Empty name for clean display
        completionData: (0..<45).map { i in
            DayCompletion(
                date: Calendar.current.date(byAdding: .day, value: i - 44, to: Date()) ?? Date(),
                completed: [true, true, false, true, true, true, false, true, false, true][i % 10], // More realistic pattern
                count: [2, 1, 0, 3, 2, 1, 0, 2, 0, 1][i % 10]
            )
        }
    )
}

// MARK: - Widget Data Models (duplicated from Shared for now)
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
    let id: UUID
    let date: Date
    let completed: Bool
    let count: Int
    
    init(date: Date, completed: Bool, count: Int = 0) {
        self.id = UUID()
        self.date = date
        self.completed = completed
        self.count = count
    }
}

// MARK: - Contribution Graph Views
struct CompactContributionGraphView: View {
    let data: HabitWidgetData
    
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    
    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 9), spacing: cellSpacing) {
                ForEach(data.completionData) { day in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(colorForCompletion(day))
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }
    
    private func colorForCompletion(_ day: DayCompletion) -> Color {
        if !day.completed {
            return Color(.systemGray5)
        }
        
        let level = min(day.count, 4)
        switch level {
        case 0:
            return Color(.systemGray5)
        case 1:
            return Color(.systemGreen).opacity(0.6) // Light green, adapts to dark mode
        case 2:
            return Color(.systemGreen).opacity(0.75) // Medium green
        case 3:
            return Color(.systemGreen).opacity(0.9) // Strong green
        default:
            return Color(.systemGreen) // Full system green, adapts to dark mode
        }
    }
}

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HabitWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HabitWidgetEntryView(entry: entry)
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your Habitica habit progress with a GitHub-style contribution graph.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habitData: createSampleHabitData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), habitData: loadHabitData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let habitData = loadHabitData()
        
        // Create entries for the next 24 hours, updating every hour
        var entries: [SimpleEntry] = []
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, habitData: habitData)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadHabitData() -> HabitWidgetData? {
        NSLog("🔍 Widget: Attempting to load habit data from UserDefaults")
        
        guard let userDefaults = UserDefaults(suiteName: "group.com.yourname.StrikeChart") else {
            NSLog("❌ Widget: Failed to create UserDefaults with suite name")
            return nil
        }
        
        // Check what keys exist
        let allKeys = userDefaults.dictionaryRepresentation().keys
        NSLog("🗝️ Widget: Available UserDefaults keys: \(Array(allKeys))")
        
        guard let data = userDefaults.data(forKey: "habitData") else {
            NSLog("⚠️ Widget: No data found for key 'habitData'")
            return nil
        }
        
        NSLog("📦 Widget: Found habit data, size: \(data.count) bytes")
        
        guard let habitData = try? JSONDecoder().decode(HabitWidgetData.self, from: data) else {
            NSLog("❌ Widget: Failed to decode habit data")
            return nil
        }
        
        NSLog("✅ Widget: Successfully loaded habit data - ID: \(habitData.habitId), Name: '\(habitData.habitName)', Days: \(habitData.completionData.count)")
        return habitData
    }
    

}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let habitData: HabitWidgetData?
}

struct HabitWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if let habitData = entry.habitData {
                switch family {
                case .systemSmall:
                    SmallWidgetView(data: habitData)
                case .systemMedium:
                    MediumWidgetView(data: habitData)
                default:
                    SmallWidgetView(data: habitData)
                }
            } else {
                // Show sample data only when no real data is available
                let sampleData = createSampleHabitData()
                switch family {
                case .systemSmall:
                    SmallWidgetView(data: sampleData)
                case .systemMedium:
                    MediumWidgetView(data: sampleData)
                default:
                    SmallWidgetView(data: sampleData)
                }
            }
        }
    }
}

struct SmallWidgetView: View {
    let data: HabitWidgetData
    
    var body: some View {
        VStack(spacing: 4) {
            CompactContributionGraphView(data: data)
        }
        .padding(8)
    }
}

struct MediumWidgetView: View {
    let data: HabitWidgetData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strike Chart")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(data.habitName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(currentStreak(data: data.completionData))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            CompactContributionGraphView(data: data)
        }
        .padding()
    }
    
    private func currentStreak(data: [DayCompletion]) -> Int {
        let sortedData = data.sorted { $0.date > $1.date }
        var streak = 0
        
        for completion in sortedData {
            if completion.completed {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strike Chart")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Select a habit")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            
            Text("Open the app to connect to Habitica and select a habit to track.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
}

// Preview removed for iOS 16.0 compatibility
// Widget previews require iOS 17.0+