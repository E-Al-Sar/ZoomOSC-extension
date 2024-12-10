import SwiftUI

struct ParticipantDetailMockup: View {
    let participant: Participant
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @EnvironmentObject private var automationManager: AutomationManager
    @State private var message = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Participant header
                HStack {
                    VStack(alignment: .leading) {
                        Text(participant.name)
                            .font(.title)
                        Text(participant.role.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "person.circle")
                        .font(.system(size: 44))
                }
                .padding()
                
                // Status controls
                HStack(spacing: 30) {
                    Button {
                        Task {
                            // Toggle mute
                            let command = "userName/\(participant.id.uuidString)/\(participant.isMuted ? "unMute" : "mute")"
                            let message = OSCMessage("/zoom/\(command)")
                            try? await oscManager.sendOSCMessage(message)
                        }
                    } label: {
                        VStack {
                            Image(systemName: participant.isMuted ? "mic.slash.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(participant.isMuted ? "Unmute" : "Mute")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        Task {
                            // Toggle video
                            let command = "userName/\(participant.id.uuidString)/\(participant.hasVideo ? "stopVideo" : "startVideo")"
                            let message = OSCMessage("/zoom/\(command)")
                            try? await oscManager.sendOSCMessage(message)
                        }
                    } label: {
                        VStack {
                            Image(systemName: participant.hasVideo ? "video.circle.fill" : "video.slash.circle.fill")
                                .font(.system(size: 24))
                            Text(participant.hasVideo ? "Stop Video" : "Start Video")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        Task {
                            if participant.isPinned {
                                try? await oscManager.unpinParticipant(participant.id.uuidString)
                            } else {
                                try? await oscManager.pinParticipant(participant.id.uuidString)
                            }
                        }
                    } label: {
                        VStack {
                            Image(systemName: participant.isPinned ? "pin.circle.fill" : "pin.circle")
                                .font(.system(size: 24))
                            Text(participant.isPinned ? "Unpin" : "Pin")
                                .font(.caption)
                        }
                    }
                    
                    // Add spotlight control
                    Button {
                        Task {
                            if participant.isSpotlighted {
                                try? await oscManager.unspotlightParticipant(participant.id.uuidString)
                            } else {
                                try? await oscManager.spotlightParticipant(participant.id.uuidString)
                            }
                        }
                    } label: {
                        VStack {
                            Image(systemName: participant.isSpotlighted ? "sparkles.square.fill" : "sparkles.square")
                                .font(.system(size: 24))
                            Text(participant.isSpotlighted ? "Unspotlight" : "Spotlight")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                // Quick actions
                GroupBox("Quick Actions") {
                    HStack {
                        Button("Send Greeting") {
                            automationManager.sendGreeting(to: participant)
                        }
                        Divider()
                        Button("Lower Hand") {
                            Task {
                                try? await oscManager.lowerParticipantHand(participant.id.uuidString)
                            }
                        }
                        .disabled(!participant.handRaised)
                    }
                    .padding(.vertical, 4)
                }
                
                // Quick message
                VStack(alignment: .leading) {
                    Text("Quick Message")
                        .font(.headline)
                    HStack {
                        TextField("Type a message...", text: $message)
                            .textFieldStyle(.roundedBorder)
                        Button("Send") {
                            Task {
                                try? await oscManager.sendChatToUser(message, userID: participant.id.uuidString)
                                message = ""
                            }
                        }
                        .disabled(message.isEmpty)
                    }
                }
                .padding()
                
                // Recent activity
                GroupBox("Recent Activity") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let lastActive = participant.lastActiveTime {
                            HStack {
                                Image(systemName: "clock")
                                Text("Last Active: \(lastActive.formatted())")
                            }
                        }
                        
                        if participant.handRaised {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.yellow)
                                Text("Hand Raised")
                            }
                        }
                        
                        ForEach(participant.tags, id: \.self) { tag in
                            HStack {
                                Image(systemName: "tag.fill")
                                Text("Tagged as: \(tag)")
                            }
                        }
                    }
                    .font(.callout)
                }
            }
            .padding()
        }
        .navigationTitle(participant.name)
    }
}

#Preview {
    ParticipantDetailMockup(participant: Participant(id: UUID(), name: "John Doe", role: .student))
} 