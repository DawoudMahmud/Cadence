import WidgetKit
import SwiftUI

// Shared with the main app. Both target this app group; widget reads,
// the app writes from WidgetData.swift.
private let appGroupID = "group.com.dawoudmahmud.cadence"
private let summariesKey = "latestSnapshots"

struct WidgetSummary: Codable, Hashable {
    let platform: String       // raw value of Platform
    let followers: Int
    let delta: Int?
    let updatedAt: Date

    var displayName: String {
        switch platform {
        case "instagram": return "Instagram"
        case "tiktok":    return "TikTok"
        default:          return platform.capitalized
        }
    }

    var symbolName: String {
        switch platform {
        case "instagram": return "camera"
        case "tiktok":    return "music.note"
        default:          return "circle"
        }
    }
}

private func loadSummaries() -> [WidgetSummary] {
    guard let defaults = UserDefaults(suiteName: appGroupID),
          let data = defaults.data(forKey: summariesKey),
          let summaries = try? JSONDecoder().decode([WidgetSummary].self, from: data) else {
        return []
    }
    return summaries
}

struct CadenceEntry: TimelineEntry {
    let date: Date
    let summaries: [WidgetSummary]

    static let placeholder = CadenceEntry(
        date: .now,
        summaries: [
            WidgetSummary(platform: "instagram", followers: 12_345, delta: 28,  updatedAt: .now),
            WidgetSummary(platform: "tiktok",    followers: 4_210,  delta: -3,  updatedAt: .now),
        ]
    )
}

struct CadenceProvider: TimelineProvider {
    func placeholder(in context: Context) -> CadenceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CadenceEntry) -> ()) {
        let entry = CadenceEntry(date: .now, summaries: loadSummaries())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CadenceEntry>) -> ()) {
        let entry = CadenceEntry(date: .now, summaries: loadSummaries())
        // Refresh in 1h or whenever the app calls reloadAllTimelines() — whichever comes first.
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct CadenceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CadenceEntry

    var body: some View {
        if entry.summaries.isEmpty {
            emptyState
        } else if family == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Log stats in Cadence")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var smallView: some View {
        let primary = entry.summaries.first!
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: primary.symbolName)
                Text(primary.displayName)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            Spacer()
            Text(primary.followers, format: .number)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("followers")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let delta = primary.delta {
                deltaLabel(delta)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            ForEach(entry.summaries, id: \.platform) { s in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: s.symbolName)
                        Text(s.displayName)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    Text(s.followers, format: .number)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let delta = s.delta {
                        deltaLabel(delta)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func deltaLabel(_ delta: Int) -> some View {
        let symbol = delta >= 0 ? "arrow.up.right" : "arrow.down.right"
        let color: Color = delta >= 0 ? .green : .red
        return Label(delta.formatted(.number.sign(strategy: .always())),
                     systemImage: symbol)
            .font(.caption2)
            .foregroundStyle(color)
    }
}

struct CadenceWidget: Widget {
    let kind: String = "CadenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CadenceProvider()) { entry in
            CadenceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cadence")
        .description("Latest follower count and recent change.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CadenceWidget()
} timeline: {
    CadenceEntry.placeholder
}

#Preview(as: .systemMedium) {
    CadenceWidget()
} timeline: {
    CadenceEntry.placeholder
}
