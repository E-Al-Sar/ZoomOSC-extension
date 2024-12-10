import Foundation
import SwiftUI
import Combine

@MainActor
class AutomationManager: ObservableObject {
    static let shared = AutomationManager()
    
    // Automation settings
    @Published var autoPinEnabled = false
    @Published var autoGreetEnabled = false
    @Published var autoTagEnabled = true
    
    // Pin settings
    @Published var pinPriority: [String] = ["Host", "Teacher", "VIP"] // Tags in order of priority
    @Published var maxPinnedParticipants = 2 // Maximum number of participants to pin
    
    // Greeting settings
    @Published var greetingMessages: [String: String] = [
        "Host": "Welcome, Host!",
        "Teacher": "Welcome, Teacher!",
        "Student": "Welcome to class!",
        "VIP": "Welcome, VIP!",
        "default": "Welcome to the meeting!"
    ]
    
    // Name-based criteria
    struct NameCriteria: Identifiable {
        let id = UUID()
        let tag: String
        let pattern: String
    }
    
    @Published var nameCriteria: [NameCriteria] = [
        NameCriteria(tag: "Host", pattern: "^Host"),
        NameCriteria(tag: "Student", pattern: "^STU"),
        NameCriteria(tag: "Teacher", pattern: "^TCH"),
        NameCriteria(tag: "Guest", pattern: "^GST"),
        NameCriteria(tag: "VIP", pattern: "^VIP")
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .participantJoined)
            .sink { [weak self] notification in
                guard let participant = notification.object as? Participant else { return }
                self?.handleParticipantJoined(participant)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .participantLeft)
            .sink { [weak self] notification in
                guard let participant = notification.object as? Participant else { return }
                self?.handleParticipantLeft(participant)
            }
            .store(in: &cancellables)
    }
    
    private func handleParticipantJoined(_ participant: Participant) {
        if autoGreetEnabled {
            sendGreeting(to: participant)
        }
        
        if autoPinEnabled {
            Task {
                await updatePinnedParticipants()
            }
        }
    }
    
    private func handleParticipantLeft(_ participant: Participant) {
        if autoPinEnabled && participant.isPinned {
            Task {
                await updatePinnedParticipants()
            }
        }
    }
    
    func sendGreeting(to participant: Participant) {
        // Find the most appropriate greeting based on participant's tags
        let greeting = participant.tags.first { tag in
            greetingMessages[tag] != nil
        }.flatMap { tag in
            greetingMessages[tag]
        } ?? greetingMessages["default"] ?? "Welcome!"
        
        Task {
            try? await OSCCommunicationManager.shared.sendChatToUser(greeting, userID: participant.id.uuidString)
        }
    }
    
    private func updatePinnedParticipants() async {
        let activeParticipants = ParticipantManager.shared.getActiveParticipants()
        
        // Unpin all currently pinned participants
        for participant in activeParticipants where participant.isPinned {
            try? await OSCCommunicationManager.shared.unpinParticipant(participant.id.uuidString)
        }
        
        // Find participants to pin based on priority
        var pinnedCount = 0
        var participantsToPin: [Participant] = []
        
        for tag in pinPriority {
            let taggedParticipants = activeParticipants.filter { $0.tags.contains(tag) }
            for participant in taggedParticipants {
                if pinnedCount < maxPinnedParticipants {
                    participantsToPin.append(participant)
                    pinnedCount += 1
                } else {
                    break
                }
            }
            if pinnedCount >= maxPinnedParticipants {
                break
            }
        }
        
        // Pin selected participants
        for (index, participant) in participantsToPin.enumerated() {
            if index == 0 {
                try? await OSCCommunicationManager.shared.pinParticipant(participant.id.uuidString)
            } else {
                try? await OSCCommunicationManager.shared.addPinParticipant(participant.id.uuidString)
            }
        }
    }
    
    // MARK: - Settings Management
    
    func addNameCriteria(tag: String, pattern: String) {
        let criteria = NameCriteria(tag: tag, pattern: pattern)
        nameCriteria.append(criteria)
    }
    
    func removeNameCriteria(_ tag: String) {
        nameCriteria.removeAll { $0.tag == tag }
    }
    
    func addPinPriorityTag(_ tag: String) {
        if !pinPriority.contains(tag) {
            pinPriority.append(tag)
            Task {
                if autoPinEnabled {
                    await updatePinnedParticipants()
                }
            }
        }
    }
    
    func removePinPriorityTag(_ tag: String) {
        pinPriority.removeAll { $0 == tag }
        Task {
            if autoPinEnabled {
                await updatePinnedParticipants()
            }
        }
    }
    
    func setGreetingMessage(for tag: String, message: String) {
        greetingMessages[tag] = message
    }
    
    func setMaxPinnedParticipants(_ count: Int) {
        maxPinnedParticipants = max(1, min(count, 9)) // ZoomOSC supports up to 9 pins
        Task {
            if autoPinEnabled {
                await updatePinnedParticipants()
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let participantJoined = Notification.Name("participantJoined")
    static let participantLeft = Notification.Name("participantLeft")
} 