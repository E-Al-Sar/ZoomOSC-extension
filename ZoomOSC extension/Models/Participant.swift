import AppKit
import SwiftData

@Model
class Participant {
    @Attribute(.unique) var id: UUID
    var name: String
    var tags: [String]
    var joinCount: Int
    var lastJoinDate: Date?
    
    // Additional tracking fields
    var isOnline: Bool
    var isMuted: Bool
    var hasVideo: Bool
    var handRaised: Bool
    var isSpotlighted: Bool
    var isPinned: Bool
    var role: ParticipantRole
    var lastActiveTime: Date?
    var lastSpeakingTime: Date?
    
    init(id: UUID = UUID(), 
         name: String, 
         tags: [String] = [], 
         joinCount: Int = 0, 
         lastJoinDate: Date? = nil,
         isOnline: Bool = false,
         isMuted: Bool = true,
         hasVideo: Bool = false,
         handRaised: Bool = false,
         isSpotlighted: Bool = false,
         isPinned: Bool = false,
         role: ParticipantRole = .attendee,
         lastActiveTime: Date? = nil,
         lastSpeakingTime: Date? = nil) {
        self.id = id
        self.name = name
        self.tags = tags
        self.joinCount = joinCount
        self.lastJoinDate = lastJoinDate
        self.isOnline = isOnline
        self.isMuted = isMuted
        self.hasVideo = hasVideo
        self.handRaised = handRaised
        self.isSpotlighted = isSpotlighted
        self.isPinned = isPinned
        self.role = role
        self.lastActiveTime = lastActiveTime
        self.lastSpeakingTime = lastSpeakingTime
    }
}

enum ParticipantRole: Int, Codable {
    case attendee = 0
    case panelist = 1
    case coHost = 2
    case host = 3
} 