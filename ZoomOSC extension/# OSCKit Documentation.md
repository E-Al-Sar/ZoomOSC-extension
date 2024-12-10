# OSCKit Documentation

## Getting Started

### Introduction
OSCKit is a Swift framework for working with the Open Sound Control (OSC) protocol. It provides functionality for sending and receiving OSC messages over UDP networks.

### Installation

Import the full library with networking I/O:
```swift
import OSCKit
```

Or import core functionality without networking I/O:
```swift
import OSCKitCore
```

### Key Components

#### Core Classes
- **OSCClient**: Sends OSC messages over UDP
- **OSCServer**: Receives OSC messages on a specific UDP port
- **OSCSocket**: Combines client and server functionality using a single local port

#### Value Types
1. **Core OSC Types**
   - `Int32` (big-endian)
   - `Float32` (big-endian) 
   - `String` (null-terminated)
   - `Data` (blob)

2. **Extended OSC Types**
   - `Bool`
   - `Int64` (big-endian)
   - `Double` (big-endian)
   - `Character` (ASCII)
   - `OSCArrayValue` (array container)
   - `OSCTimeTag` (uint64)
   - `OSCStringAltValue` (alternative string)
   - `OSCMIDIValue` (MIDI message)
   - `OSCImpulseValue` (impulse/infinitum/bang)
   - `OSCNullValue` (null)

3. **Interpolated Types**
   - `Int` → `Int32`
   - `Int8/Int16` → `Int32`
   - `UInt` → `Int64`
   - `UInt8/UInt16` → `Int32`
   - `UInt32` → `Int64`
   - `Float16` → `Float32`
   - `Float80` → `Double`
   - `Substring` → `String`

## Sending OSC Messages

### Using OSCClient

```swift
// Initialize client
let oscClient = OSCClient()

// Send a single message
let msg = OSCMessage("/test", values: ["string", 123])
try oscClient.send(msg, to: "192.168.1.2", port: 8000)

// Send multiple messages as a bundle
let msg1 = OSCMessage("/msg1")
let msg2 = OSCMessage("/msg2", values: ["string", 123])
let bundle = OSCBundle([msg1, msg2])
try oscClient.send(bundle, to: "192.168.1.2", port: 8000)
```

### Time-Tagged Bundles
```swift
// Send bundle with future time tag
let bundle = OSCBundle(timeTag: .timeIntervalSinceNow(5.0), [msg1, msg2])
try oscClient.send(bundle, to: "192.168.1.2", port: 8000)
```

## Receiving OSC Messages

### Using OSCServer

```swift
// Initialize server
let oscServer = OSCServer(port: 8000)

// Set message handler
await oscServer.setHandler { [weak self] oscMessage, timeTag in
    do {
        try self?.handle(received: oscMessage)
    } catch {
        print(error)
    }
}

// Start listening
try oscServer.start()
```

### Message Handler Implementation
```swift
private func handle(received oscMessage: OSCMessage) throws {
    // Process message based on address pattern
    switch oscMessage.addressPattern {
    case "/test":
        let value = try oscMessage.values.masked(String.self)
        print("Received test message:", value)
    default:
        print("Unhandled message:", oscMessage)
    }
}
```

## Advanced Features

### Address Pattern Parsing
OSCKit provides pattern matching for OSC addresses:

```swift
let pattern = message.addressPattern
if pattern.matches(localAddress: "/some/address/method") {
    // Handle matching message
}
```

### Using OSCAddressSpace
For automated address pattern matching:

```swift
let addressSpace = OSCAddressSpace()

// Register methods
addressSpace.register(localAddress: "/methodA") { values in
    guard let str = try? values.masked(String.self) else { return }
    // Handle methodA
}

// Handle incoming messages
func handle(message: OSCMessage) throws {
    let ids = addressSpace.dispatch(message)
    if ids.isEmpty {
        print("Unhandled message:", message)
    }
}
```

## Best Practices

1. **Client/Server Lifecycle**
   - Create single instances at app startup
   - Start servers before sending messages
   - Stop servers when done

2. **Error Handling**
   - Always wrap network operations in try-catch blocks
   - Handle connection errors gracefully
   - Validate message formats before sending

3. **Memory Management**
   - Use weak self in closures to prevent retain cycles
   - Clean up resources when stopping servers
   - Monitor bundle sizes to prevent packet fragmentation

## See Also
- [OSC 1.0 Specification](http://opensoundcontrol.org/spec-1_0)
- [OSC Time Tags](http://opensoundcontrol.org/spec-1_0#timetags)
- [OSC Address Patterns](http://opensoundcontrol.org/spec-1_0#osc-address-pattern)

