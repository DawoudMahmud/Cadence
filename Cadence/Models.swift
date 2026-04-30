import Foundation
import SwiftData

enum Platform: String, CaseIterable, Codable, Identifiable {
    case instagram
    case tiktok

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        }
    }

    var symbolName: String {
        switch self {
        case .instagram: return "camera"
        case .tiktok:    return "music.note"
        }
    }
}

enum IdeaStatus: String, CaseIterable, Codable, Identifiable {
    case idea
    case filming
    case editing
    case posted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idea:    return "Idea"
        case .filming: return "Filming"
        case .editing: return "Editing"
        case .posted:  return "Posted"
        }
    }
}

@Model
final class StatSnapshot {
    var date: Date
    var platformRaw: String
    var followers: Int
    var posts: Int
    var engagement: Int

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .instagram }
        set { platformRaw = newValue.rawValue }
    }

    init(date: Date = .now,
         platform: Platform,
         followers: Int,
         posts: Int = 0,
         engagement: Int = 0) {
        self.date = date
        self.platformRaw = platform.rawValue
        self.followers = followers
        self.posts = posts
        self.engagement = engagement
    }
}

@Model
final class Idea {
    var title: String
    var notes: String
    var statusRaw: String
    var platformRaw: String?
    var createdAt: Date

    var status: IdeaStatus {
        get { IdeaStatus(rawValue: statusRaw) ?? .idea }
        set { statusRaw = newValue.rawValue }
    }

    var platform: Platform? {
        get { platformRaw.flatMap(Platform.init(rawValue:)) }
        set { platformRaw = newValue?.rawValue }
    }

    init(title: String,
         notes: String = "",
         status: IdeaStatus = .idea,
         platform: Platform? = nil,
         createdAt: Date = .now) {
        self.title = title
        self.notes = notes
        self.statusRaw = status.rawValue
        self.platformRaw = platform?.rawValue
        self.createdAt = createdAt
    }
}
