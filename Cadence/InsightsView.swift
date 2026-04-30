import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \StatSnapshot.date) private var snapshots: [StatSnapshot]

    @State private var platform: Platform = .instagram

    private var filtered: [StatSnapshot] {
        snapshots.filter { $0.platform == platform }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filtered.count < 2 {
                        ContentUnavailableView(
                            "Need a few data points",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Log at least two stat snapshots on \(platform.displayName) to see insights.")
                        )
                        .frame(minHeight: 300)
                    } else {
                        growthRateCard
                        bestStretchCard
                        weekdayCard
                        postsImpactCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Cards

    private var growthRateCard: some View {
        let stats = GrowthStats(snapshots: filtered)
        return card(title: "Growth rate") {
            HStack {
                rateBlock(label: "Last 7 days",  daily: stats.dailyAverage(daysBack: 7))
                Divider()
                rateBlock(label: "Last 30 days", daily: stats.dailyAverage(daysBack: 30))
                Divider()
                rateBlock(label: "All time",     daily: stats.allTimeDaily)
            }
        }
    }

    private func rateBlock(label: String, daily: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let daily {
                let rounded = daily.rounded()
                Text("\(rounded >= 0 ? "+" : "")\(Int(rounded))/day")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(rounded >= 0 ? .green : .red)
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bestStretchCard: some View {
        let stats = GrowthStats(snapshots: filtered)
        return card(title: "Best 7-day stretch") {
            if let best = stats.bestSevenDay {
                VStack(alignment: .leading, spacing: 4) {
                    Text("+\(best.delta) followers")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.green)
                    Text("\(best.start.formatted(date: .abbreviated, time: .omitted)) → \(best.end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Need at least 7 days of data.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private var weekdayCard: some View {
        let stats = GrowthStats(snapshots: filtered)
        return card(title: "Growth by weekday") {
            if stats.weekdayAverages.values.allSatisfy({ $0 == 0 }) {
                Text("Log on different weekdays to see this.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Chart {
                    ForEach(stats.weekdayAveragesSorted, id: \.weekday) { item in
                        BarMark(
                            x: .value("Weekday", item.label),
                            y: .value("Avg gain", item.average)
                        )
                        .foregroundStyle(item.average >= 0 ? Color.green : Color.red)
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var postsImpactCard: some View {
        let stats = GrowthStats(snapshots: filtered)
        return card(title: "Posts vs growth") {
            if let perPost = stats.followerGainPerPost {
                let rounded = Int(perPost.rounded())
                let sign = rounded >= 0 ? "+" : ""
                Text("\(sign)\(rounded) followers per post")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(rounded >= 0 ? .green : .red)
                Text("Average across all logged periods where you reported posting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Log posts in your snapshots to see this.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Stats engine

private struct GrowthStats {
    let snapshots: [StatSnapshot]   // sorted ascending by date

    var allTimeDaily: Double? {
        guard let first = snapshots.first, let last = snapshots.last,
              first !== last else { return nil }
        let days = max(last.date.timeIntervalSince(first.date) / 86_400, 1)
        return Double(last.followers - first.followers) / days
    }

    func dailyAverage(daysBack: Int) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: .now) ?? .now
        let recent = snapshots.filter { $0.date >= cutoff }
        guard let first = recent.first, let last = recent.last, first !== last else { return nil }
        let days = max(last.date.timeIntervalSince(first.date) / 86_400, 1)
        return Double(last.followers - first.followers) / days
    }

    var bestSevenDay: (start: Date, end: Date, delta: Int)? {
        guard snapshots.count >= 2 else { return nil }
        var best: (Date, Date, Int)?
        for i in 0..<snapshots.count {
            let start = snapshots[i]
            for j in (i+1)..<snapshots.count {
                let end = snapshots[j]
                let span = end.date.timeIntervalSince(start.date)
                if span > 7 * 86_400 { break }
                let delta = end.followers - start.followers
                if best == nil || delta > best!.2 {
                    best = (start.date, end.date, delta)
                }
            }
        }
        return best.map { (start: $0.0, end: $0.1, delta: $0.2) }
    }

    /// Average follower gain attributed to each weekday based on consecutive snapshots.
    var weekdayAverages: [Int: Double] {
        var sums: [Int: Int] = [:]
        var counts: [Int: Int] = [:]
        for i in 1..<snapshots.count {
            let prev = snapshots[i - 1]
            let curr = snapshots[i]
            let weekday = Calendar.current.component(.weekday, from: curr.date)
            let delta = curr.followers - prev.followers
            sums[weekday, default: 0] += delta
            counts[weekday, default: 0] += 1
        }
        var averages: [Int: Double] = [:]
        for w in 1...7 {
            if let count = counts[w], count > 0 {
                averages[w] = Double(sums[w] ?? 0) / Double(count)
            } else {
                averages[w] = 0
            }
        }
        return averages
    }

    var weekdayAveragesSorted: [(weekday: Int, label: String, average: Double)] {
        let labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (1...7).map { w in
            (weekday: w, label: labels[w - 1], average: weekdayAverages[w] ?? 0)
        }
    }

    var followerGainPerPost: Double? {
        var totalGain = 0
        var totalPosts = 0
        for i in 1..<snapshots.count {
            let prev = snapshots[i - 1]
            let curr = snapshots[i]
            totalGain += curr.followers - prev.followers
            totalPosts += curr.posts
        }
        guard totalPosts > 0 else { return nil }
        return Double(totalGain) / Double(totalPosts)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [StatSnapshot.self, Idea.self], inMemory: true)
}
