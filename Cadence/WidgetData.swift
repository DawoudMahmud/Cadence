import Foundation
import SwiftData
import WidgetKit

/// Bridges the app's SwiftData store and the widget's lightweight read cache.
/// The app writes a small JSON summary to a shared App Group UserDefaults so
/// the widget can render without spinning up SwiftData.
enum WidgetData {

    static let appGroupID = "group.com.dawoudmahmud.cadence"
    private static let summariesKey = "latestSnapshots"

    struct Summary: Codable, Hashable {
        let platform: String
        let followers: Int
        let delta: Int?
        let updatedAt: Date
    }

    static func refresh(from snapshots: [StatSnapshot]) {
        var byPlatform: [Platform: [StatSnapshot]] = [:]
        for s in snapshots {
            byPlatform[s.platform, default: []].append(s)
        }
        var summaries: [Summary] = []
        for platform in Platform.allCases {
            let items = (byPlatform[platform] ?? []).sorted(by: { $0.date < $1.date })
            guard let last = items.last else { continue }
            let delta: Int? = items.count >= 2
                ? last.followers - items[items.count - 2].followers
                : nil
            summaries.append(Summary(platform: platform.rawValue,
                                     followers: last.followers,
                                     delta: delta,
                                     updatedAt: last.date))
        }
        write(summaries)
    }

    private static func write(_ summaries: [Summary]) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(summaries) else { return }
        defaults.set(data, forKey: summariesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
