import XCTest
@testable import ZoomOSC_extension

@MainActor
class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        notificationManager = NotificationManager.shared
    }
    
    func testNotificationForParticipantJoin() async throws {
        let participant = TestHelpers.createMockParticipant()
        await notificationManager.notifyParticipantJoined(participant)
        // Add assertions for notification delivery
    }
} 