@Model
class Participant {
    @Attribute(.unique) var id: UUID
    var name: String
    var tags: [String]
    var joinCount: Int
    var lastJoinDate: Date?

    init(id: UUID = UUID(), name: String, tags: [String] = [], joinCount: Int = 0, lastJoinDate: Date? = nil) {
        self.id = id
        self.name = name
        self.tags = tags
        self.joinCount = joinCount
        self.lastJoinDate = lastJoinDate
    }
}
