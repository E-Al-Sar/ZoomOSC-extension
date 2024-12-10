import SwiftUI
import SwiftData

struct MockupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @EnvironmentObject private var automationManager: AutomationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @Query(sort: \Participant.name) private var participants: [Participant]
    @State private var selectedTab = 0
    @State private var isConnected = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationSplitView {
            List {
                // Debug section
                Section("Debug") {
                    DisclosureGroup("Debug Info") {
                        Text("Total Participants: \(participants.count)")
                        Text("Active Count (OSC): \(oscManager.activeParticipantCount)")
                        Text("Connection Status: \(oscManager.isConnected ? "Connected" : "Disconnected")")
                    }
                }
                
                // Connection section
                Section("Connection") {
                    HStack {
                        Circle()
                            .fill(oscManager.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(oscManager.isConnected ? "Connected" : "Disconnected")
                        Spacer()
                        Button(oscManager.isConnected ? "Disconnect" : "Connect") {
                            Task {
                                if oscManager.isConnected {
                                    await oscManager.stopListening()
                                } else {
                                    try? await oscManager.startListening()
                                }
                            }
                        }
                    }
                }
                
                // Participants section with sorting and filtering
                Section("Participants") {
                    if participants.isEmpty {
                        Text("No participants")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(participants.filter { $0.isOnline }) { participant in
                            NavigationLink {
                                ParticipantDetailMockup(participant: participant)
                            } label: {
                                ParticipantRowMockup(participant: participant)
                            }
                            .contextMenu {
                                ParticipantContextMenu(participant: participant)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ZoomOSC")
            .toolbar {
                ToolbarItem {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
        } detail: {
            Text("Select a participant")
        }
    }
}

struct ParticipantRowMockup: View {
    let participant: Participant
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(participant.name)
                .font(.headline)
            HStack {
                ForEach(participant.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tagColor(for: tag))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                if participant.isMuted {
                    Image(systemName: "mic.slash")
                        .foregroundColor(.red)
                }
                if participant.handRaised {
                    Image(systemName: "hand.raised")
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                Task {
                    let command = participant.isMuted ? "unMute" : "mute"
                    try? await oscManager.sendOSCMessage(OSCMessage("/zoom/userName/\(participant.id.uuidString)/\(command)"))
                }
            } label: {
                Label(participant.isMuted ? "Unmute" : "Mute", systemImage: participant.isMuted ? "mic" : "mic.slash")
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
                Label(participant.isPinned ? "Unpin" : "Pin", systemImage: "pin")
            }
            
            if participant.handRaised {
                Button {
                    Task {
                        try? await oscManager.lowerParticipantHand(participant.id.uuidString)
                    }
                } label: {
                    Label("Lower Hand", systemImage: "hand.raised")
                }
            }
        }
    }
    
    private func tagColor(for tag: String) -> Color {
        switch tag {
        case "Host":
            return .purple
        case "Teacher":
            return .blue
        case "Student":
            return .green
        case "VIP":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    MockupView()
} 