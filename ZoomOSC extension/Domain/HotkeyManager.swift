import Foundation
import SwiftUI
import Carbon.HIToolbox
import OSCKit

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    // Hotkey definitions
    struct Hotkey {
        let keyCode: Int
        let modifiers: NSEvent.ModifierFlags
        let action: () async throws -> Void
    }
    
    // Default hotkeys
    private var hotkeys: [Hotkey] = []
    
    private init() {
        setupDefaultHotkeys()
    }
    
    private func setupDefaultHotkeys() {
        // Cmd + Shift + M: Toggle Mute All
        hotkeys.append(Hotkey(
            keyCode: kVK_ANSI_M,
            modifiers: [.command, .shift],
            action: { [weak self] in
                try await OSCCommunicationManager.shared.muteAll()
            }
        ))

        // Cmd + Shift + H: Lower All Hands
        hotkeys.append(Hotkey(
            keyCode: kVK_ANSI_H,
            modifiers: [.command, .shift],
            action: { [weak self] in
                try await OSCCommunicationManager.shared.lowerAllHands()
            }
        ))
        
        // Cmd + Shift + P: Toggle Auto-Pin
        hotkeys.append(Hotkey(
            keyCode: kVK_ANSI_P,
            modifiers: [.command, .shift],
            action: { [weak self] in
                await MainActor.run {
                    AutomationManager.shared.autoPinEnabled.toggle()
                }
            }
        ))
        
        // Cmd + Shift + G: Toggle Auto-Greet
        hotkeys.append(Hotkey(
            keyCode: kVK_ANSI_G,
            modifiers: [.command, .shift],
            action: { [weak self] in
                await MainActor.run {
                    AutomationManager.shared.autoGreetEnabled.toggle()
                }
            }
        ))
    }
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Check if the event matches any of our hotkeys
        for hotkey in hotkeys {
            if event.keyCode == hotkey.keyCode &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == hotkey.modifiers {
                Task {
                    do {
                        try await hotkey.action()
                    } catch {
                        print("Error executing hotkey action: \(error)")
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Key Codes
private let kVK_ANSI_M: Int = 0x2E
private let kVK_ANSI_H: Int = 0x04
private let kVK_ANSI_P: Int = 0x23
private let kVK_ANSI_G: Int = 0x05 
