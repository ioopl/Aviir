# Aviir App

A SwiftUI Bluetooth Low Energy (BLE) scanner and proximity radar that discovers nearby devices, visualizes their relative distance, and enables basic peer-to-peer “ping” communication.

---

## Technical Requirements

**Architecture:** MVVM + Coordinator Pattern  
**Language:** Swift  
**UI:** SwiftUI (chosen for declarative layout, state-driven updates, and easy previews)  
**Frameworks:** CoreBluetooth, Combine  

The App follows a clean separation of concerns:
- **Model / Service:** `ProximityBLE` handles all CoreBluetooth logic (advertising, scanning, GATT setup, lifecycle).
- **ViewModel:** e.g. `BLEViewModel`, `MainViewModel` expose observable state (`@Published`) to drive SwiftUI views.
- **View:** e.g. `BLEView`, `RadarBLEView`, `MainVew` render state and relay user actions upward via closures or VM methods.
- **Coordinator:** `AppCoordinator` handles navigation flow (Splash → Tabs → Main/BLE).

Error handling, empty states, and permission prompts (for Bluetooth authorization) are implemented to give clear user feedback.

---

## Notes on Decisions/trade-offs (Justification for Using SwiftUI)

SwiftUI was chosen over UIKit to:
- Faster UI design.
- Reactively update radar visuals as RSSI changes.
- Simplify state binding between BLE service and UI (`@Published` + `@ObservedObject`). Alternatives would have been UIKit, Delegates (Protocols), or Closures (Callbacks), NotificationCenter
- Reduce boilerplate and make previews (`#Preview`) for rapid BLE UI testing.
- Support cross-platform expansion (watchOS / macOS) with minimal refactor.

---

## Core Components

### **1. ProximityBLE (Service Layer)**
Handles Bluetooth lifecycle — advertising, scanning, and communication.

**Simplified BLE GATT concept:**
> BLE = Bluetooth Low Energy → the wireless protocol.  
> GATT = Generic Attribute Profile → the “language and menu” of data exchange.

The MCU (firmware) exposes a **GATT table** of services & characteristics (UUIDs) that the app can interact with rather than directly talking to the physical chips.

**Analogy 🗄️**  
Think of the board as a restaurant kitchen:
- The chips are the chefs (temperature chef, motor chef, etc.).
- The MCU is the head chef who talks to them.
- The menu that gets handed to you (the app) is the GATT table with UUIDs.
- We don’t order directly from the line cooks (chips).
- We only order from the menu (UUIDs) that the head chef (firmware) wrote.

**Example:**

- On one iPhone A, the App advertises serviceUUID and characteristic charUUID.
- On second iPhone B, the App also advertises and scans for the exact same serviceUUID.
- Each of these has a UUID so the App can find it and talk read/write/subscribe to each other via the App.
- The UUIDs belong to the Bluetooth services/characteristics, not to the physical chips themselves.

---

### **2. BLEViewModel**
Bridges `ProximityBLE` and the UI.  
Publishes:
```swift
@Published var peers: [String: Double]    // nearby devices (name → RSSI)
@Published var pingedNames: Set<String>   // devices recently pinged
@Published var readyNames: Set<String>    // devices fully connected & ready
```

--- 


## How to run the project
- Clone or unzip the repo.
- Open the .xcodeproj or .xcworkspace in Xcode 15.2+.
- Build & run on two real iPhones (Bluetooth doesn’t work in Simulator).
- On first launch, allow Bluetooth permission when prompted.
- Open the app on two devices → they appear on each other’s radar.
- Tap “Ping” to send a pulse animation to the other peer.
- Note: If you deny Bluetooth access, the app shows a “Go to Settings” alert on the Scanner screen.
