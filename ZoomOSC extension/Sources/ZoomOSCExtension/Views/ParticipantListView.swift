import SwiftUI
import SwiftData
import OSCKit

struct ParticipantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Participant.name) private var participants: [Participant]
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @State private var showDebugInfo = false
    
    var body: some View {
        List {
            // Debug info section
            DisclosureGroup("Debug Info") {
                Text("Total Participants: \(participants.count)")
                Text("Active Count (OSC): \(oscManager.activeParticipantCount)")
            }
            
            // Participant list
            Section {
                if participants.isEmpty {
                    Text("No participants")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(participants) { participant in
                        ParticipantRowView(participant: participant)
                            .contextMenu {
                                ParticipantContextMenu(participant: participant)
                            }
                    }
                }
            } header: {
                Text("Participants")
            }
        }
        .navigationTitle("Participants")
        .listStyle(.sidebar)
    }
}

struct ParticipantRowView: View {
    let participant: Participant
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(participant.name)
                    .font(.headline)
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 8) {
                    if participant.handRaised {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.yellow)
                    }
                    if participant.isMuted {
                        Image(systemName: "mic.slash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Tags
            if !participant.tags.isEmpty {
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
                }
            }
        }
        .padding(.vertical, 4)
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