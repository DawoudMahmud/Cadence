import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "sparkles") }

            IdeasView()
                .tabItem { Label("Ideas", systemImage: "lightbulb") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [StatSnapshot.self, Idea.self], inMemory: true)
}
