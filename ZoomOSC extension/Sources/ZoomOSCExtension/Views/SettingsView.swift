import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var automationManager: AutomationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var oscManager: OSCCommunicationManager
    
    @State private var newTag = ""
    @State private var newGreeting = ""
    @State private var selectedTagForGreeting: String?
    @State private var newCriteria = ""
    @State private var newKeyword = ""
    
    // OSC Connection Settings
    @AppStorage("oscReceivePort") private var receivePort: Int = 1246
    @AppStorage("oscSendPort") private var sendPort: Int = 9090
    @AppStorage("oscHost") private var host: String = "192.168.2.1"
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func validatePorts() -> Bool {
        return receivePort > 0 && receivePort < 65536 &&
               sendPort > 0 && sendPort < 65536 &&
               receivePort != sendPort
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // OSC Connection
                GroupBox("OSC Connection") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Host:")
                            TextField("Host (e.g., 127.0.0.1)", text: $host)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Receive Port:")
                            TextField("Port", value: $receivePort, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Send Port:")
                            TextField("Port", value: $sendPort, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button("Apply Connection Settings") {
                            if validatePorts() {
                                Task {
                                    do {
                                        try await oscManager.connect(
                                            host: host,
                                            receivePort: receivePort,
                                            sendPort: sendPort
                                        )
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            } else {
                                errorMessage = "Invalid port numbers. Please use values between 1-65535"
                                showError = true
                            }
                        }
                        .alert("Connection Error", isPresented: $showError) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(errorMessage)
                        }
                        
                        Button("Test Connection") {
                            Task {
                                do {
                                    try await oscManager.testConnection()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                        
                        if oscManager.isConnected {
                            Text("Connected")
                                .foregroundColor(.green)
                        } else {
                            Text("Disconnected")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
                
                // Participant Criteria
                GroupBox("Participant Criteria") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(automationManager.nameCriteria, id: \.tag) { criteria in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(criteria.tag)
                                        .font(.headline)
                                    Text("Pattern: \(criteria.pattern)")
                                        .font(.caption)
                                }
                                Spacer()
                                Button(action: {
                                    automationManager.removeNameCriteria(criteria.tag)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        VStack {
                            HStack {
                                TextField("Tag (e.g., Chicago)", text: $newTag)
                                TextField("Pattern (e.g., CHI-)", text: $newKeyword)
                            }
                            Button("Add Criteria") {
                                if !newTag.isEmpty && !newKeyword.isEmpty {
                                    automationManager.addNameCriteria(tag: newTag, pattern: newKeyword)
                                    newTag = ""
                                    newKeyword = ""
                                }
                            }
                            .disabled(newTag.isEmpty || newKeyword.isEmpty)
                        }
                    }
                    .padding()
                }
                
                // Automation Settings
                GroupBox("Automation") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Auto-Pin Participants", isOn: $automationManager.autoPinEnabled)
                        Toggle("Auto-Greet Participants", isOn: $automationManager.autoGreetEnabled)
                        
                        if automationManager.autoPinEnabled {
                            Stepper(
                                "Max Pinned: \(automationManager.maxPinnedParticipants)",
                                value: Binding(
                                    get: { automationManager.maxPinnedParticipants },
                                    set: { automationManager.setMaxPinnedParticipants($0) }
                                ),
                                in: 1...9
                            )
                        }
                    }
                    .padding()
                }
                
                // Pin Priority Settings
                GroupBox("Pin Priority") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(automationManager.pinPriority, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button(action: {
                                    automationManager.removePinPriorityTag(tag)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("New tag", text: $newTag)
                            Button("Add") {
                                if !newTag.isEmpty {
                                    automationManager.addPinPriorityTag(newTag)
                                    newTag = ""
                                }
                            }
                            .disabled(newTag.isEmpty)
                        }
                    }
                    .padding()
                }
                
                // Greeting Messages
                GroupBox("Greeting Messages") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(automationManager.greetingMessages.keys), id: \.self) { tag in
                            if let message = automationManager.greetingMessages[tag] {
                                VStack(alignment: .leading) {
                                    Text(tag)
                                        .font(.headline)
                                    Text(message)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Picker("Select Tag", selection: $selectedTagForGreeting) {
                            Text("Default").tag("default" as String?)
                            ForEach(automationManager.pinPriority, id: \.self) { tag in
                                Text(tag).tag(tag as String?)
                            }
                        }
                        
                        TextField("New greeting message", text: $newGreeting)
                        
                        Button("Set Greeting") {
                            if let tag = selectedTagForGreeting, !newGreeting.isEmpty {
                                automationManager.setGreetingMessage(for: tag, message: newGreeting)
                                newGreeting = ""
                            }
                        }
                        .disabled(selectedTagForGreeting == nil || newGreeting.isEmpty)
                    }
                    .padding()
                }
                
                // Notifications
                GroupBox("Notifications") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable Notifications", isOn: $notificationManager.notificationsEnabled)
                        Toggle("Enable Sounds", isOn: $notificationManager.soundEnabled)
                        
                        ForEach(Array(notificationManager.priorityTagsForNotification), id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button(action: {
                                    notificationManager.removePriorityTag(tag)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("New notification tag", text: $newTag)
                            Button("Add") {
                                if !newTag.isEmpty {
                                    notificationManager.addPriorityTag(newTag)
                                    newTag = ""
                                }
                            }
                            .disabled(newTag.isEmpty)
                        }
                    }
                    .padding()
                }
                
                // Hotkeys
                GroupBox("Hotkeys") {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("⌘ + ⇧ + M: Toggle Mute All")
                        Text("⌘ + ⇧ + H: Lower All Hands")
                        Text("⌘ + ⇧ + P: Toggle Auto-Pin")
                        Text("⌘ + ⇧ + G: Toggle Auto-Greet")
                    }
                    .font(.caption)
                    .padding()
                }
            }
            .padding()
        }
    }
} 
