import Foundation
import UserNotifications
import SwiftUI
import OSCKit

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // Notification settings
    @Published var notificationsEnabled = true
    @Published var soundEnabled = true
    @Published var priorityTagsForNotification: Set<String> = ["Host", "Teacher", "VIP"]
    
    // Notification categories
    private let categoryJoin = "PARTICIPANT_JOIN"
    private let categoryLeave = "PARTICIPANT_LEAVE"
    private let categoryHandRaise = "HAND_RAISE"
    private let categoryChat = "CHAT_MESSAGE"
    
    override private init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
        
        // Configure notification categories and actions
        let joinCategory = UNNotificationCategory(
            identifier: categoryJoin,
            actions: [
                UNNotificationAction(
                    identifier: "PIN_PARTICIPANT",
                    title: "Pin Participant",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "SEND_GREETING",
                    title: "Send Greeting",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let handRaiseCategory = UNNotificationCategory(
            identifier: categoryHandRaise,
            actions: [
                UNNotificationAction(
                    identifier: "LOWER_HAND",
                    title: "Lower Hand",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            joinCategory,
            handRaiseCategory
        ])
        
        // Set delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Notification Triggers
    
    func notifyParticipantJoined(_ participant: Participant) {
        guard notificationsEnabled else { return }
        
        // Check if participant has any priority tags
        let hasImportantTag = !Set(participant.tags).intersection(priorityTagsForNotification).isEmpty
        
        // Only notify for priority participants
        if hasImportantTag {
            let content = UNMutableNotificationContent()
            content.title = "Participant Joined"
            content.body = "\(participant.name) has joined the meeting"
            if soundEnabled {
                content.sound = .default
            }
            content.userInfo = ["participantID": participant.id.uuidString]
            content.categoryIdentifier = categoryJoin
            
            // Add tag information to notification
            let tags = Set(participant.tags).intersection(priorityTagsForNotification)
            if !tags.isEmpty {
                content.subtitle = "Tags: \(Array(tags).joined(separator: ", "))"
            }
            
            let request = UNNotificationRequest(
                identifier: "join_\(participant.id.uuidString)",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func notifyParticipantLeft(_ participant: Participant) {
        guard notificationsEnabled else { return }
        
        // Only notify for priority participants
        let participantTags = Set(participant.tags)
        if !participantTags.intersection(priorityTagsForNotification).isEmpty {
            let content = UNMutableNotificationContent()
            content.title = "Participant Left"
            content.body = "\(participant.name) has left the meeting"
            if soundEnabled {
                content.sound = .default
            }
            content.categoryIdentifier = categoryLeave
            
            let request = UNNotificationRequest(
                identifier: "leave_\(participant.id.uuidString)",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func notifyHandRaised(_ participant: Participant) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Hand Raised"
        content.body = "\(participant.name) raised their hand"
        if soundEnabled {
            content.sound = .default
        }
        content.userInfo = ["participantID": participant.id.uuidString]
        content.categoryIdentifier = categoryHandRaise
        
        let request = UNNotificationRequest(
            identifier: "hand_\(participant.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func notifyChatMessage(_ message: ChatMessage, from participant: Participant) {
        guard notificationsEnabled else { return }
        
        // Only notify for priority participants
        let participantTags = Set(participant.tags)
        if !participantTags.intersection(priorityTagsForNotification).isEmpty {
            let content = UNMutableNotificationContent()
            content.title = "New Message from \(participant.name)"
            content.body = message.content
            if soundEnabled {
                content.sound = .default
            }
            content.categoryIdentifier = categoryChat
            
            let request = UNNotificationRequest(
                identifier: "chat_\(message.id.uuidString)",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - Settings Management
    
    func addPriorityTag(_ tag: String) {
        priorityTagsForNotification.insert(tag)
    }
    
    func removePriorityTag(_ tag: String) {
        priorityTagsForNotification.remove(tag)
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
    
    func toggleSound() {
        soundEnabled.toggle()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        Task {
            switch response.actionIdentifier {
            case "PIN_PARTICIPANT":
                if let participantID = userInfo["participantID"] as? String {
                    try? await OSCCommunicationManager.shared.pinParticipant(participantID)
                }
                
            case "SEND_GREETING":
                if let participantID = userInfo["participantID"] as? String,
                   let uuid = UUID(uuidString: participantID),
                   let participant = ParticipantManager.shared.getParticipant(withID: uuid) {
                    AutomationManager.shared.sendGreeting(to: participant)
                }
                
            case "LOWER_HAND":
                if let participantID = userInfo["participantID"] as? String {
                    let command = "userName/\(participantID)/lowerHand"
                    let message = OSCMessage("/zoom/\(command)")
                    try? await OSCCommunicationManager.shared.sendOSCMessage(message)
                }
                
            default:
                break
            }
            
            completionHandler()
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
} 