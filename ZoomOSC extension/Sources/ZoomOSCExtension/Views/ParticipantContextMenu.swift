import SwiftUI
import OSCKit

struct ParticipantContextMenu: View {
    let participant: Participant
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @EnvironmentObject private var automationManager: AutomationManager
    
    var body: some View {
        Group {
            Button(participant.isPinned ? "Unpin" : "Pin") {
                Task {
                    if participant.isPinned {
                        try? await oscManager.unpinParticipant(participant.id.uuidString)
                    } else {
                        try? await oscManager.pinParticipant(participant.id.uuidString)
                    }
                }
            }
            
            Button("Send Message") {
                // You'll need to implement this through your navigation or state management
                // This could open the chat view with this participant selected
            }
            
            if participant.handRaised {
                Button("Lower Hand") {
                    Task {
                        let command = "userName/\(participant.id.uuidString)/lowerHand"
                        let message = OSCMessage("/zoom/\(command)")
                        try? await oscManager.sendOSCMessage(message)
                    }
                }
            }
            
            Menu("Quick Messages") {
                ForEach(Array(automationManager.greetingMessages.keys), id: \.self) { key in
                    if let message = automationManager.greetingMessages[key] {
                        Button(key) {
                            Task {
                                try? await oscManager.sendChatToUser(
                                    message,
                                    userID: participant.id.uuidString
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}