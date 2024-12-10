import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var useMockup = true  // Toggle this to switch between implementations
    
    var body: some View {
        if useMockup {
            MockupView()
        } else {
            MainView()  // Original implementation
        }
    }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    @EnvironmentObject private var automationManager: AutomationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        NavigationSplitView {
            TabView(selection: $selectedTab) {
                ParticipantListView()
                    .tabItem {
                        Label("Participants", systemImage: "person.2")
                    }
                    .tag(0)
                
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "message")
                    }
                    .tag(1)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ConnectionStatusView(isConnected: oscManager.isConnected)
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
        } detail: {
            Text("Select a participant or chat message")
        }
    }
} 