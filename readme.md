# ProximityBLE
/*
 On iPhone 12, the app advertises serviceUUID and characteristic charUUID.
 On iPhone 6, the app also advertises and scans for the exact same serviceUUID.
 So they see and talk to each other.
 */
/*
 Analogy 🗄️
 Imagine the device (the pump) is a filing cabinet with drawers.
 Each drawer = Service (e.g., Pump Control, Temperature Sensors).
 Inside the drawer, there are folders = Characteristics (e.g., suction level, temperature value).
 Each folder has a label (UUID) so your app can find it.
 You can read, write, or subscribe to updates in these folders.
 */
/*
  So: UUIDs belong to the Bluetooth services/characteristics, not to the physical chips themselves.
 */

# BLE GATT
/*
 BLE GATT in plain English
 BLE = Bluetooth Low Energy → the technology your phone uses to talk wirelessly to small devices (like pumps, watches, or sensors).
 GATT = Generic Attribute Profile.
 Think of GATT as the "language and dictionary" that your phone and the device agree to use.
 */
/*
 Analogy 📦
 Think of the board as a restaurant kitchen:
 The chips are the chefs (temperature chef, motor chef, etc.).
 The MCU is the head chef who talks to them.
 The menu that gets handed to you (the app) is the GATT table with UUIDs.
 You don’t order directly from the line cooks (chips).
 You only order from the menu (UUIDs) that the head chef (firmware) wrote.
 */

# BLEViewModel
// peers is a dictionary of nearby Bluetooth devices the User phone has detected. So peers means: “Who’s around me right now, and how close are they?
// The key (String) is each peer’s identifier (name or UUID).
// The value (Double) is its RSSI — a measure of how strong the Bluetooth signal is (a proxy for distance).
// e.g. ["Umair-iPhone": -47.0, "Test-iPad": -75.0]
@Published var peers: [String: Double] = [:]

// pingedNames is a set of peer names we recently sent a "ping" to. This is often used to:
// wake up a nearby device,
// confirm it’s responsive,
// trigger an action (like syncing or playing a sound).
@Published private(set) var pingedNames: Set<String> = []

// readyNames are the peers that have completed the handshake which means they are fully connected and ready for interaction.
// Sequence looks like this:
// Device A discovers Device B → add to peers
// Device A sends ping → add to pingedNames
// Device B replies / confirms ready → move to readyNames
// So if readyNames contains a peer, you know the connection is stable enough to exchange data or commands.
@Published var readyNames: Set<String> = []


# BLEView
/*
 BLEView (feature/container view like a View controller)
 Purpose: The full BLE screen that composes the radar + list + buttons.
 Owns UI orchestration: shows empty state, list of peers, buttons for Ping/Favorite, titles.
 Talks to the ViewModel: calls vm.sendPing(to:), reads vm.peers, vm.readyNames, etc.
 Navigation/presentation: decides when to present sheets, alerts, etc. (if any).
*/

# RadarBLEView
/*
 RadarBLEView (child/presentational view)
 Purpose: Draws the circular "radar" visualization.
 Inputs only: peers (name → RSSI), pingedNames, readyNames, and an onPing closure.
 No state/persistence/networking. It just renders dots/labels/animations based on the properties we pass.
 Reusable & testable: We could drop it into any screen (even in a different app) and it still work if given the same inputs.
 */

