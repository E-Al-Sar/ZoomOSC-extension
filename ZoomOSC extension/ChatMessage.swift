@Model
class ChatMessage {
    @Attribute(.unique) var id: UUID
    var participantID: UUID
    var content: String
    var timestamp: Date

    init(id: UUID = UUID(), participantID: UUID, content: String, timestamp: Date = Date()) {
        self.id = id
        self.participantID = participantID
        self.content = content
        self.timestamp = timestamp