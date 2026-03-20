import Foundation

public enum NotificationType: String, Codable, Sendable, Equatable {
    case encounterLiked = "encounter_liked"
    case encounterCommented = "encounter_commented"
}
