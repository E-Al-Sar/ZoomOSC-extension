@MainActor
final class ParticipantManager: ObservableObject {
    static let shared = ParticipantManager()
    private var modelContext: ModelContext?
    
    // Track current session
    private(set) var currentSessionID: UUID?
    
    // Criteria for automatic tagging
    private var nameCriteria: [(String, String)] = [
        ("Host", "^Host"),
        ("Student", "^STU"),
        ("Teacher", "^TCH"),
        ("Guest", "^GST"),
        ("VIP", "^VIP")
    ]
    
    private init() {}
    
    func initialize(with context: ModelContext) {
        guard modelContext == nil else {
            print("ParticipantManager already initialized")
            return
        }
        modelContext = context
    }
    
    private func ensureInitialized() {
        guard modelContext != nil else {
            fatalError("ParticipantManager not initialized with context")
        }
    }
    
    // MARK: - Session Management
    
    func clearParticipants() {
        ensureInitialized()
        let participants = getAllParticipants()
        participants.forEach { modelContext?.delete($0) }
        try? modelContext?.save()
    }
    
    func archiveSession(_ sessionID: UUID) {
        ensureInitialized()
        let participants = getAllParticipants()
        participants.forEach { participant in
            participant.lastSessionID = sessionID
            participant.isOnline = false
        }
        try? modelContext?.save()
    }
    
    // MARK: - Participant Updates
    
    func handleParticipantUpdate(
        id: String,
        name: String,
        isOnline: Bool? = nil,
        hasVideo: Bool? = nil,
        isMuted: Bool? = nil,
        handRaised: Bool? = nil,
        role: ParticipantRole? = nil
    ) {
        ensureInitialized()
        
        do {
            let descriptor = FetchDescriptor<Participant>(
                predicate: #Predicate<Participant> { participant in
                    participant.name == name
                }
            )
            
            if let existingParticipant = try modelContext?.fetch(descriptor).first {
                if let isOnline = isOnline {
                    existingParticipant.isOnline = isOnline
                    if isOnline {
                        existingParticipant.lastActiveTime = Date()
                    }
                }
                if let hasVideo = hasVideo {
                    existingParticipant.hasVideo = hasVideo
                }
                if let isMuted = isMuted {
                    existingParticipant.isMuted = isMuted
                }
                if let handRaised = handRaised {
                    existingParticipant.handRaised = handRaised
                }
                if let role = role {
                    existingParticipant.role = role
                }
                updateParticipantTags(existingParticipant)
            } else {
                let participant = Participant(
                    id: UUID(),
                    name: name,
                    isOnline: isOnline ?? true,
                    isMuted: isMuted ?? false,
                    hasVideo: hasVideo ?? false,
                    handRaised: handRaised ?? false,
                    role: role ?? .attendee,
                    lastActiveTime: isOnline == true ? Date() : nil
                )
                updateParticipantTags(participant)
                modelContext?.insert(participant)
            }
            
            try modelContext?.save()
        } catch {
            print("ERROR: Failed to update participant \(name): \(error)")
        }
    }
    
    // MARK: - Status Updates
    
    func updateParticipantStatus(
        id: UUID,
        isOnline: Bool? = nil,
        isMuted: Bool? = nil,
        hasVideo: Bool? = nil,
        handRaised: Bool? = nil,
        isSpotlighted: Bool? = nil,
        isPinned: Bool? = nil,
        role: ParticipantRole? = nil
    ) {
        ensureInitialized()
        guard let participant = getParticipant(withID: id) else { return }
        
        if let isOnline = isOnline {
            participant.isOnline = isOnline
            if isOnline {
                participant.lastActiveTime = Date()
            }
        }
        
        if let isMuted = isMuted { participant.isMuted = isMuted }
        if let hasVideo = hasVideo { participant.hasVideo = hasVideo }
        if let handRaised = handRaised { participant.handRaised = handRaised }
        if let isSpotlighted = isSpotlighted { participant.isSpotlighted = isSpotlighted }
        if let isPinned = isPinned { participant.isPinned = isPinned }
        if let role = role { participant.role = role }
        
        try? modelContext?.save()
    }
    
    // MARK: - Tagging Logic
    
    private func updateParticipantTags(_ participant: Participant) {
        var newTags = Set<String>()
        
        // Apply name-based criteria
        for (tag, pattern) in nameCriteria {
            if participant.name.range(of: pattern, options: .regularExpression) != nil {
                newTags.insert(tag)
            }
        }
        
        // Add role-based tag
        newTags.insert(participant.role.description)
        
        // Update participant tags
        participant.tags = Array(newTags)
    }
    
    // MARK: - Queries
    
    func getParticipant(withID id: UUID) -> Participant? {
        ensureInitialized()
        let descriptor = FetchDescriptor<Participant>(
            predicate: #Predicate<Participant> { participant in
                participant.id == id
            }
        )
        return try? modelContext?.fetch(descriptor).first
    }
    
    func getActiveParticipants() -> [Participant] {
        ensureInitialized()
        let descriptor = FetchDescriptor<Participant>(
            predicate: #Predicate<Participant> { participant in
                participant.isOnline == true
            }
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    func getAllParticipants() -> [Participant] {
        ensureInitialized()
        let descriptor = FetchDescriptor<Participant>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
} 