@MainActor
class OSCManager: ObservableObject {
    static let shared = OSCManager()
    
    @Published private(set) var isConnected = false
    
    // Move existing OSC communication code here...
} 