import XCTest
import OSCKit
@testable import ZoomOSC_extension

class TestHelpers {
    static func createMockOSCMessage(address: String, values: [any OSCValue] = []) -> OSCMessage {
        return OSCMessage(address, values: values)
    }
    
    static func createMockParticipant(id: UUID = UUID(), 
                                    name: String = "Test User",
                                    isOnline: Bool = true) -> Participant {
        let participant = Participant(id: id, name: name)
        participant.isOnline = isOnline
        return participant
    }
} 