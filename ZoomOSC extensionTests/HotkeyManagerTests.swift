import XCTest
import Carbon
@testable import ZoomOSC_extension

@MainActor
class HotkeyManagerTests: XCTestCase {
    var hotkeyManager: HotkeyManager!
    
    override func setUp() {
        super.setUp()
        hotkeyManager = HotkeyManager.shared
    }
    
    func testHotkeyHandling() async {
        // Create mock NSEvent
        let mockEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command, .shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "M",
            charactersIgnoringModifiers: "M",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_M)
        )!
        
        let handled = hotkeyManager.handleKeyEvent(mockEvent)
        XCTAssertTrue(handled, "Hotkey should be handled")
    }
} 