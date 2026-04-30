import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }

            IdeasView()
                .tabItem { Label("Ideas", systemImage: "lightbulb") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [StatSnapshot.self, Idea.self], inMemory: true)
}
