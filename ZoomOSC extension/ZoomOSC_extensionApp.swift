//
//  ZoomOSC_extensionApp.swift
//  ZoomOSC extension
//
//  Created by Erick Alvarez on 12/8/24.
//

import SwiftUI
import SwiftData
import OSCKit
import AppKit
import UserNotifications

@main
struct ZoomOSC_extensionApp: App {
    let modelContainer: ModelContainer
    @StateObject private var oscManager = OSCCommunicationManager.shared
    @StateObject private var automationManager = AutomationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Monitor for global hotkeys and handle notifications
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            // Set up hotkeys
            NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                _ = HotkeyManager.shared.handleKeyEvent(event)
            }
        }
    }
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        do {
            print("DEBUG: Initializing ModelContainer")
            modelContainer = try ModelContainer(
                for: Participant.self, ChatMessage.self
            )
            
            // Initialize managers with the model context
            let context = modelContainer.mainContext
            print("DEBUG: Initializing ParticipantManager with context")
            ParticipantManager.shared.initialize(with: context)
            
            print("DEBUG: Initializing ChatManager with context")
            ChatManager.shared.initialize(with: context)
        } catch {
            print("ERROR: Could not initialize application: \(error)")
            fatalError("Could not initialize application: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(oscManager)
                .environmentObject(automationManager)
                .environmentObject(notificationManager)
                .task {
                    // Start OSC communication when the view appears
                    do {
                        try await oscManager.startListening()
                    } catch {
                        print("Failed to start OSC communication: \(error)")
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}


