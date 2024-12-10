import Foundation
import SwiftUI
import OSCKit

@MainActor
class OSCCommunicationManager: ObservableObject {
    static let shared = OSCCommunicationManager()
    
    // Connection state
    @Published var isConnected = false
    @Published var activeParticipantCount: Int = 0
    @Published var lastError: String?
    
    // OSC client and server
    private var oscClient: OSCClient?
    private var oscServer: OSCServer?
    
    // Current connection settings
    internal var currentHost: String = "192.168.2.1"
    internal var currentReceivePort: Int = 1246
    internal var currentSendPort: Int = 9090
    
    // Add session management
    @Published private(set) var currentSessionID: UUID?
    
    private init() {}
    
    func startListening() async throws {
        // Start a new session
        currentSessionID = UUID()
        
        // Clear previous session participants
        ParticipantManager.shared.clearParticipants()
        
        try await connect(
            host: UserDefaults.standard.string(forKey: "oscHost") ?? "192.168.2.1",
            receivePort: UserDefaults.standard.integer(forKey: "oscReceivePort"),
            sendPort: UserDefaults.standard.integer(forKey: "oscSendPort")
        )
    }
    
    func connect(host: String, receivePort: Int, sendPort: Int) async throws {
        // Stop existing connections
        if oscServer != nil || oscClient != nil {
            await stopListening()
        }
        
        do {
            // Initialize OSC client
            let client = OSCClient()
            try await client.start()
            
            // Initialize OSC server with correct configuration
            let server = OSCServer(port: UInt16(receivePort))
            
            // Capture weak self in the handler
            weak var weakSelf = self
            await server.setHandler { (message: OSCMessage, timeTag: OSCTimeTag?) in
                Task { @MainActor in
                    guard let self = weakSelf else { return }
                    do {
                        try self.handle(received: message)
                    } catch {
                        print("Error handling message:", error)
                    }
                }
            }
            
            try await server.start()
            
            // Store successful connection
            self.oscClient = client
            self.oscServer = server
            self.currentHost = host
            self.currentReceivePort = receivePort
            self.currentSendPort = sendPort
            self.isConnected = true
            self.lastError = nil
            
            // Save settings
            UserDefaults.standard.set(host, forKey: "oscHost")
            UserDefaults.standard.set(receivePort, forKey: "oscReceivePort")
            UserDefaults.standard.set(sendPort, forKey: "oscSendPort")
            
            // Subscribe to ZoomOSC events and enable tracking
            try await sendInitialCommands()
            
        } catch {
            self.lastError = error.localizedDescription
            throw error
        }
    }
    
    func stopListening() async {
        // Archive current session
        if let sessionID = currentSessionID {
            ParticipantManager.shared.archiveSession(sessionID)
        }
        currentSessionID = nil
        
        if let server = oscServer {
            await server.stop()
        }
        if let client = oscClient {
            await client.stop()
        }
        oscServer = nil
        oscClient = nil
        isConnected = false
    }
    
    private func sendInitialCommands() async throws {
        // First enable subscription to all events
        let subscribeMsg = OSCMessage("/zoom/subscribe", values: [1 as Int32])
        try await sendOSCMessage(subscribeMsg)
        print("DEBUG: Sent subscribe command")
        
        // Then enable gallery tracking
        let trackMsg = OSCMessage("/zoom/galTrackMode", values: [1 as Int32])
        try await sendOSCMessage(trackMsg)
        print("DEBUG: Sent gallery tracking command")
        
        // Add a small delay to ensure commands are processed
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Finally request the participant list
        let listMsg = OSCMessage("/zoom/list")
        try await sendOSCMessage(listMsg)
        print("DEBUG: Sent list command")
    }
    
    func sendOSCMessage(_ message: OSCMessage) async throws {
        guard let client = oscClient, isConnected else {
            throw NSError(domain: "OSCCommunication", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Not connected to OSC"
            ])
        }
        
        try await client.send(message, to: currentHost, port: UInt16(currentSendPort))
    }
    
    // MARK: - Message Handling
    
    internal func handle(received message: OSCMessage) throws {
        print("DEBUG: Received OSC message: \(message.addressPattern)")
        print("DEBUG: Message values: \(message.values)")
        
        let pattern = message.addressPattern.description
        
        // Check if it's a user-specific event
        if pattern.hasPrefix("/zoomosc/user/") {
            handleUserEvent(message)
        }
        // Check if it's a global event
        else if pattern.hasPrefix("/zoomosc/") {
            handleGlobalEvent(message)
        }
        else {
            print("DEBUG: Unhandled message pattern: \(pattern)")
        }
    }
    
    private func handleUserEvent(_ message: OSCMessage) {
        let addressStr = message.addressPattern.description
        print("DEBUG: Processing user event: \(addressStr)")
        
        // Parse the standard user prefix (4 values: targetIndex, userName, galleryIndex, zoomID)
        guard message.values.count >= 4,
              let userName = message.values[1] as? String else {
            print("DEBUG: Invalid user message format - values: \(message.values)")
            return
        }
        
        let pathComponents = addressStr.split(separator: "/").map(String.init)
        let eventType = pathComponents.last ?? ""
        
        print("DEBUG: User event details:")
        print("  - Address: \(addressStr)")
        print("  - Type: \(eventType)")
        print("  - User: \(userName)")
        print("  - Values: \(message.values)")
        
        switch eventType {
        case "list":
            // Handle list message with full status
            guard message.values.count >= 8,
                  let userRole = message.values[4] as? Int32,
                  let onlineStatus = message.values[5] as? Int32,
                  let audioStatus = message.values[7] as? Int32,
                  let handRaised = message.values.count > 8 ? message.values[8] as? Int32 : 0 else {
                print("DEBUG: ❌ Invalid list status format for user \(userName)")
                return
            }
            
            Task { @MainActor in
                ParticipantManager.shared.handleParticipantUpdate(
                    id: userName,
                    name: userName,
                    isOnline: onlineStatus == 1,
                    isMuted: audioStatus == 0,
                    handRaised: handRaised == 1,
                    role: ParticipantRole(rawValue: Int(userRole)) ?? .attendee
                )
            }
            
        case "online":
            ParticipantManager.shared.handleParticipantUpdate(
                id: userName,
                name: userName,
                isOnline: true
            )
            
        case "offline":
            ParticipantManager.shared.handleParticipantUpdate(
                id: userName,
                name: userName,
                isOnline: false
            )
            
        case "handRaised":
            ParticipantManager.shared.handleParticipantUpdate(
                id: userName,
                name: userName,
                handRaised: true
            )
            
        case "handLowered":
            ParticipantManager.shared.handleParticipantUpdate(
                id: userName,
                name: userName,
                handRaised: false
            )
            
        case "chat":
            guard message.values.count >= 7,
                  let senderName = message.values[1] as? String,
                  let content = message.values[4] as? String,
                  let zoomID = message.values[5] as? String,
                  let messageType = message.values[6] as? Int32 else {
                print("DEBUG: Invalid chat message format")
                print("DEBUG: Values received: \(message.values)")
                return
            }
            
            // messageType: 1 = to all, 4 = to me
            print("DEBUG: Chat message from \(senderName) (ZoomID: \(zoomID)) - Type: \(messageType)")
            
            Task { @MainActor in
                ChatManager.shared.handleNewMessage(
                    from: zoomID, // Using ZoomID instead of name for consistency
                    content: content
                )
            }
            
        default:
            print("DEBUG: Unhandled user event type: \(eventType)")
        }
    }
    
    private func handleGlobalEvent(_ message: OSCMessage) {
        let pattern = message.addressPattern.description
        
        print("DEBUG: Handling global event: \(pattern)")
        print("DEBUG: Message values: \(message.values)")
        
        switch pattern {
        case "/zoomosc/galleryCount":
            if let count = message.values.first as? Int32 {
                activeParticipantCount = Int(count)
                print("DEBUG: Updated gallery count: \(count)")
            }
            
        case "/zoomosc/galleryOrder":
            // Handle gallery order updates
            print("DEBUG: Received gallery order update")
            
        case "/zoomosc/listCleared":
            print("DEBUG: List cleared")
            Task {
                let participants = ParticipantManager.shared.getAllParticipants()
                for participant in participants {
                    ParticipantManager.shared.handleParticipantUpdate(
                        id: participant.name,
                        name: participant.name,
                        isOnline: false
                    )
                }
            }
            
        default:
            // Only log truly unhandled events
            if !pattern.hasPrefix("/zoomosc/user/") && !pattern.hasPrefix("/zoomosc/me/") {
                print("DEBUG: Unhandled global event: \(pattern)")
            }
        }
    }
    
    // MARK: - Common Commands
    
    func muteAll() async throws {
        let message = OSCMessage("/zoom/all/mute", values: [])
        try await sendOSCMessage(message)
    }
    
    func unmuteAll() async throws {
        let message = OSCMessage("/zoom/all/unMute", values: [])
        try await sendOSCMessage(message)
    }
    
    func lowerAllHands() async throws {
        let message = OSCMessage("/zoom/lowerAllHands", values: [])
        try await sendOSCMessage(message)
    }
    
    func sendChatToAll(_ message: String) async throws {
        let oscMessage = OSCMessage("/zoom/chatAll", values: [message])
        try await sendOSCMessage(oscMessage)
    }
    
    func sendChatToUser(_ message: String, userID: String) async throws {
        let command = "/zoom/userName/\(userID)/chat"
        let oscMessage = OSCMessage(command, values: [message])
        try await sendOSCMessage(oscMessage)
    }
    
    // MARK: - Pin Commands
    
    func pinParticipant(_ userID: String) async throws {
        let command = "userName/\(userID)/pin"
        let message = OSCMessage("/zoom/\(command)", values: [])
        try await sendOSCMessage(message)
        
        if let uuid = UUID(uuidString: userID) {
            ParticipantManager.shared.updateParticipantStatus(id: uuid, isPinned: true)
        }
    }
    
    func addPinParticipant(_ userID: String) async throws {
        let command = "userName/\(userID)/addPin"
        let message = OSCMessage("/zoom/\(command)", values: [])
        try await sendOSCMessage(message)
    }
    
    func unpinParticipant(_ userID: String) async throws {
        let command = "userName/\(userID)/unPin"
        let message = OSCMessage("/zoom/\(command)", values: [])
        try await sendOSCMessage(message)
        
        if let uuid = UUID(uuidString: userID) {
            ParticipantManager.shared.updateParticipantStatus(id: uuid, isPinned: false)
        }
    }
    
    func clearAllPins() async throws {
        let message = OSCMessage("/zoom/clearPin", values: [])
        try await sendOSCMessage(message)
        
        let participants = ParticipantManager.shared.getAllParticipants()
        participants.forEach { participant in
            ParticipantManager.shared.updateParticipantStatus(id: participant.id, isPinned: false)
        }
    }
    
    func reconnect(host: String, receivePort: Int, sendPort: Int) async throws {
        try await connect(host: host, receivePort: receivePort, sendPort: sendPort)
    }
    
    func testConnection() async throws {
        // Send a ping command to test connection
        let pingMsg = OSCMessage("/zoom/ping", values: ["test"])
        try await sendOSCMessage(pingMsg)
        print("DEBUG: Sent ping command")
    }
    
    deinit {
        Task {
            await stopListening()
        }
    }
} 

/// OSC Message Patterns:
/// - /zoom/subscribe: Subscribe to all events (value: 1)
/// - /zoom/galTrackMode: Enable gallery tracking (value: 1)
/// - /zoom/list: Request participant list
/// - /zoom/all/mute: Mute all participants
/// - /zoom/all/unMute: Unmute all participants
/// - /zoom/lowerAllHands: Lower all raised hands
/// - /zoom/chatAll: Send chat message to all (value: message)
/// - /zoom/userName/{id}/chat: Send chat to specific user
/// - /zoom/userName/{id}/pin: Pin specific user
/// - /zoom/userName/{id}/unPin: Unpin specific user
/// - /zoom/clearPin: Clear all pins 
