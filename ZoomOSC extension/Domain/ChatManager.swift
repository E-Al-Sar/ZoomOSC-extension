import Foundation
import SwiftData

@MainActor
class ChatManager {
    static let shared = ChatManager()
    private(set) var modelContext: ModelContext?
    
    private init() {}
    
    func initialize(with context: ModelContext) {
        guard modelContext == nil else {
            print("ChatManager already initialized")
            return
        }
        modelContext = context
    }
    
    private func ensureInitialized() {
        guard modelContext != nil else {
            fatalError("ChatManager not initialized with context")
        }
    }
    
    func handleNewMessage(from participantID: String, content: String) {
        ensureInitialized()
        guard let uuid = UUID(uuidString: participantID) else { return }
        
        let message = ChatMessage(
            participantID: uuid,
            content: content
        )
        
        modelContext?.insert(message)
        try? modelContext?.save()
    }
    
    func getMessages(for participantID: UUID) -> [ChatMessage] {
        ensureInitialized()
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate<ChatMessage> { message in
                message.participantID == participantID
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    func deleteMessage(_ message: ChatMessage) {
        ensureInitialized()
        modelContext?.delete(message)
        try? modelContext?.save()
    }
    
    func getAllMessages() -> [ChatMessage] {
        ensureInitialized()
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
} 