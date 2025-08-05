import SwiftUI

@main
struct StrikeChartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DataManager.shared)
        }
    }
}