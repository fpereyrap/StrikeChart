import SwiftUI

struct ContributionGraphView: View {
    let data: HabitWidgetData
    let showLabels: Bool
    
    init(data: HabitWidgetData, showLabels: Bool = true) {
        self.data = data
        self.showLabels = showLabels
    }
    
    private let columns = 7 // Days of the week
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    
    var body: some View {
        VStack(spacing: showLabels ? 8 : 4) {
            if showLabels {
                HStack {
                    Text(data.habitName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Last 30 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            contributionGrid
            
            if showLabels {
                legendView
            }
        }
    }
    
    private var contributionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: columns), spacing: cellSpacing) {
            ForEach(data.completionData) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForCompletion(day))
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var legendView: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(colorForLevel(level))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func colorForCompletion(_ day: DayCompletion) -> Color {
        if !day.completed {
            return Color(.systemGray5)
        }
        
        // Color intensity based on completion count
        let level = min(day.count, 4) // Cap at level 4
        return colorForLevel(level + 1) // +1 because level 0 is for no completion
    }
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0:
            return Color(.systemGray5) // No completion
        case 1:
            return Color.green.opacity(0.3) // Low completion
        case 2:
            return Color.green.opacity(0.5) // Medium-low completion
        case 3:
            return Color.green.opacity(0.7) // Medium-high completion
        case 4:
            return Color.green.opacity(0.9) // High completion
        default:
            return Color.green // Max completion
        }
    }
}

// Compact version for widget
struct CompactContributionGraphView: View {
    let data: HabitWidgetData
    
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(data.habitName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 7), spacing: cellSpacing) {
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
            return Color.green.opacity(0.4)
        case 2:
            return Color.green.opacity(0.6)
        case 3:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }
}

#Preview {
    let sampleData = HabitWidgetData(
        habitId: "sample",
        habitName: "Daily Exercise",
        completionData: (0..<30).map { i in
            DayCompletion(
                date: Calendar.current.date(byAdding: .day, value: i - 29, to: Date()) ?? Date(),
                completed: Bool.random(),
                count: Int.random(in: 0...3)
            )
        }
    )
    
    VStack(spacing: 20) {
        ContributionGraphView(data: sampleData)
            .padding()
        
        CompactContributionGraphView(data: sampleData)
            .padding()
    }
}