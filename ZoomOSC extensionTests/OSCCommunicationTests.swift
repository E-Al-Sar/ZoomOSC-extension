import XCTest
import OSCKit
@testable import ZoomOSC_extension

@MainActor
class OSCCommunicationTests: XCTestCase {
    var oscManager: OSCCommunicationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        oscManager = OSCCommunicationManager.shared
        // Initialize with default settings
        try await oscManager.connect(
            host: "192.168.2.1",
            receivePort: 1246,
            sendPort: 9090
        )
    }
    
    override func tearDown() async throws {
        await oscManager.stopListening()
        try await super.tearDown()
    }
    
    func testConnectionSettings() async throws {
        XCTAssertEqual(oscManager.currentReceivePort, 1246, "Receive port should be 1246")
        XCTAssertEqual(oscManager.currentSendPort, 9090, "Send port should be 9090")
    }
    
    func testMessageHandling() async throws {
        // Test message handling
        let message = TestHelpers.createMockOSCMessage(
            address: "/zoomosc/user/123/chat",
            values: ["Hello" as String]
        )
        
        try await oscManager.handle(received: message)
        // Add assertions based on expected behavior
    }
} 
