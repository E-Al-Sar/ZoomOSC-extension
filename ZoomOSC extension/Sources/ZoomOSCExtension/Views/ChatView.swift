import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.timestamp, order: .reverse) private var messages: [ChatMessage]
    @Query(sort: \Participant.name) private var participants: [Participant]
    
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @State private var newMessage = ""
    @State private var searchText = ""
    @State private var selectedParticipant: Participant?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var isSearching = false
    
    private var filteredParticipants: [Participant] {
        guard !searchText.isEmpty else { return [] }
        return participants.filter { participant in
            participant.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
                List {
                    ForEach(groupedMessages, id: \.0) { date, messages in
                        Section(header: Text(date.formatted(.dateTime.day().month().year()))) {
                            ForEach(messages) { message in
                                ChatMessageRow(message: message)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                
                // Message input area
                VStack(spacing: 8) {
                    // Recipient field with autocomplete
                    HStack {
                        Text("To:")
                        ZStack(alignment: .leading) {
                            if selectedParticipant == nil {
                                TextField("Everyone", text: $searchText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: searchText) { _ in
                                        isSearching = !searchText.isEmpty
                                        selectedParticipant = nil
                                    }
                            } else {
                                HStack {
                                    Text(selectedParticipant?.name ?? "")
                                    Button("×") {
                                        selectedParticipant = nil
                                        searchText = ""
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(6)
                            }
                            
                            // Autocomplete suggestions
                            if isSearching {
                                List(filteredParticipants) { participant in
                                    Button(participant.name) {
                                        selectedParticipant = participant
                                        searchText = ""
                                        isSearching = false
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(8)
                                .shadow(radius: 4)
                                .offset(y: 30)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Message input and send button
                    HStack {
                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                Task {
                                    await sendMessage()
                                }
                            }
                        
                        Button {
                            Task {
                                await sendMessage()
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                        .disabled(newMessage.isEmpty)
                    }
                    .padding()
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationTitle("Chat")
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private var groupedMessages: [(Date, [ChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func sendMessage() async {
        guard !newMessage.isEmpty else { return }
        
        do {
            if let participant = selectedParticipant {
                try await oscManager.sendChatToUser(newMessage, userID: participant.name)
            } else {
                try await oscManager.sendChatToAll(newMessage)
            }
            
            await MainActor.run {
                newMessage = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    @Query private var participants: [Participant]
    
    private var sender: Participant? {
        participants.first { $0.id == message.participantID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(sender?.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                Text(message.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(message.content)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
} 