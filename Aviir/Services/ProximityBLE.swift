import Foundation
import UIKit
import CoreBluetooth

class ProximityBLE: NSObject, ObservableObject {
    
    // MARK: - Custom UUIDs (generate with `uuidgen`)
    private let serviceUUID  = CBUUID(string: "3D42C170-9C73-4DE4-8D36-C469AA8310C8") // run in terminal # uuidgen
    private let charUUID = CBUUID(string: "23176C5D-5FF6-49A0-8FD9-900EA16AF985") // run in terminal again # uuidgen:


    // MARK: - BLE roles
    private var peripheralMgr: CBPeripheralManager!

    // MARK: - Peripheral (GATT) side
    private var characteristic: CBMutableCharacteristic?
    private var subscribedCentrals: [CBCentral] = []

    // MARK: - Central side storage
    private var peripheralsByID: [UUID: CBPeripheral] = [:]     // strong refs
    private var connectedIDs = Set<UUID>()                      // connection bookkeeping
    private var periphToChar: [UUID: CBCharacteristic] = [:]    // discovered characteristic per connected peer

    // MARK: - Peer bookkeeping
    @Published private(set) var peers: [String: Double] = [:]   // name -> smoothed RSSI
    @Published var pingedNames: Set<String> = []                // for pulsing dots
    @Published var readyNames: Set<String> = []   // peers for which char is discovered

    // Publish Bluetooth state + authorization
    @Published var bluetoothManagerState: CBManagerState = .unknown
    @Published var bluetoothAuthorizationStatus: CBManagerAuthorization = CBCentralManager.authorization
    private lazy var central: CBCentralManager = {
        // Show system power alert when Bluetooth is off
        CBCentralManager(delegate: self, queue: .main,
                         options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }()
    
    var isBluetoothAuthorized: Bool {
        switch bluetoothAuthorizationStatus {
        case .allowedAlways: return true
        case .restricted, .denied: return false
        case .notDetermined: return true // system will show the first-time prompt on use
        @unknown default: return false
        }
    }

    var isBluetoothPoweredOn: Bool {
        bluetoothManagerState == .poweredOn
    }

    // map a display name to its stable identifier (UUID string)
    private var nameToIdentifierMap: [String: String] = [:]
    
    private var nameForPeripheralID: [UUID: String] = [:]
    private var peripheralIDForName: [String: UUID] = [:]
    private var lastSeen: [String: Date] = [:]
    private var ema: [String: Double] = [:]                     // exponential moving average
    private let alpha = 0.35                                    // smoothing factor

    // MARK: - Init
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
        peripheralMgr = CBPeripheralManager(delegate: self, queue: .main)

        // Purge peers we haven't seen recently
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.purgeStale()
        }
    }

    // MARK: - Public API
    
    func sendPing(to peerName: String) {
        guard let pid = peripheralIDForName[peerName] else {
            print("❌ sendPing: no peripheral ID for \(peerName)")
            return
        }
        guard let ch = periphToChar[pid] else {
            print("❌ sendPing: characteristic not discovered for \(peerName)")
            return
        }
        guard let target = peripheralsByID[pid] else {
            print("❌ sendPing: no CBPeripheral for \(peerName)")
            return
        }
        
        let payload: [String: Any] = ["ping": true,
                                      "name": UIDevice.current.name,
                                      "ts": Date().timeIntervalSince1970]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        target.writeValue(data, for: ch, type: .withoutResponse)

        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        
        print("➡️ sendPing: wrote \(data.count) bytes to \(peerName)")
    }


    // MARK: - Housekeeping
    private func purgeStale() {
        let now = Date()
        var changed = false
        for (name, ts) in lastSeen where now.timeIntervalSince(ts) > 5 {
            ema[name] = nil
            peers[name] = nil
            lastSeen[name] = nil
            changed = true
        }
        if changed { objectWillChange.send() }
    }

    // MARK: - Advertising & Scanning
    private func advertiseIfReady() {
        guard peripheralMgr.state == .poweredOn else { return }
        setupGattIfNeeded()
        let data: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: UIDevice.current.name
        ]
        peripheralMgr.startAdvertising(data) // foreground advertising
    }

    private func scanIfReady() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [serviceUUID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    // MARK: - GATT (Peripheral) setup
    private func setupGattIfNeeded() {
        guard peripheralMgr.state == .poweredOn, characteristic == nil else { return }

        let props: CBCharacteristicProperties = [.notify, .writeWithoutResponse]
        let perms: CBAttributePermissions = [.writeable]

        let char = CBMutableCharacteristic(type: charUUID,
                                           properties: props,
                                           value: nil,
                                           permissions: perms)
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [char]

        peripheralMgr.add(service)
        characteristic = char
    }

    private func sendToSubscribers(_ data: Data) {
        guard let characteristic else { return }
        _ = peripheralMgr.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }

    // This is where the UI update comes
    private func handleIncomingPayload(_ data: Data, from source: String) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        // Optional: update name mapping if peer tells us explicitly
        if let reportedName = obj["name"] as? String, reportedName.isEmpty == false {
            // no-op: you could use this to reconcile names if needed
        }

        if let ping = obj["ping"] as? Bool, ping == true {
            let sender = (obj["name"] as? String) ?? "Peer"
            print("🔔 PING received from \(sender)")
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            
            DispatchQueue.main.async {
                self.pingedNames.insert(sender)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.pingedNames.remove(sender)
                }
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate (Peripheral role)
extension ProximityBLE: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupGattIfNeeded()
            advertiseIfReady()
        } else {
            peripheral.stopAdvertising()
            characteristic = nil
            subscribedCentrals.removeAll()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscribedCentrals.append(central)
        // Announce ourselves
        let hello = ["name": UIDevice.current.name, "ts": Date().timeIntervalSince1970] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: hello) {
            sendToSubscribers(data)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for r in requests where r.characteristic.uuid == charUUID {
            if let value = r.value {
                print("⬅️ didReceiveWrite: \(value.count) bytes")
                handleIncomingPayload(value, from: "write")
            }
            peripheral.respond(to: r, withResult: .success)
        }
    }
}

// MARK: - CBCentralManagerDelegate (Central role)
extension ProximityBLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothManagerState = central.state
        bluetoothAuthorizationStatus = CBCentralManager.authorization

        // Handle permission denied/restricted
        if !isBluetoothAuthorized {
            central.stopScan()
            peripheralsByID.removeAll()
            connectedIDs.removeAll()
            periphToChar.removeAll()
            return
        }
        
        // Normal lifecycle
        if central.state == .poweredOn {
            scanIfReady()
        } else {
            central.stopScan()
            peripheralsByID.removeAll()
            connectedIDs.removeAll()
            periphToChar.removeAll()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover p: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let rssi = RSSI.intValue
        guard rssi != 127 && rssi != 0 else { return } // ignore invalid

        // Identify peer
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? p.identifier.uuidString
        nameForPeripheralID[p.identifier] = name
        peripheralIDForName[name] = p.identifier
        lastSeen[name] = Date()

        // Smooth RSSI with EMA
        let newVal = Double(rssi)
        if let prev = ema[name] {
            ema[name] = alpha * newVal + (1 - alpha) * prev
        } else {
            ema[name] = newVal
        }
        peers[name] = ema[name]

        // --- Keep strong reference BEFORE connecting ---
        if peripheralsByID[p.identifier] == nil {
            peripheralsByID[p.identifier] = p
        }
        let peripheral = peripheralsByID[p.identifier]! // strong ref
        peripheral.delegate = self

        // Connect once, avoid spam
        if !connectedIDs.contains(peripheral.identifier) && peripheral.state == .disconnected {
            central.connect(peripheral, options: nil)
        }

        objectWillChange.send()
    }

    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        print("didConnect:", p.identifier)
        connectedIDs.insert(p.identifier)
        p.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        connectedIDs.remove(p.identifier)
        // Optionally retry after a delay if needed
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {

        connectedIDs.remove(p.identifier)
        periphToChar[p.identifier] = nil

        // Keep peripheralsByID if you want auto-reconnect; otherwise:
        // peripheralsByID[p.identifier] = nil

        if let name = nameForPeripheralID[p.identifier] {
            print("ℹ️ Disconnected \(name); clearing READY")
            DispatchQueue.main.async {
                self.readyNames.remove(name)
            }
        }
    }
    
    // Optional (slightly stricter): only insert into readyNames after the notify subscription succeeds
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == charUUID else { return }
        if let name = nameForPeripheralID[peripheral.identifier], characteristic.isNotifying {
            print("🔔 Notifications ON for \(name) — READY")
            DispatchQueue.main.async {
                self.readyNames.insert(name)
            }
        }
    }

}

// MARK: - CBPeripheralDelegate (discover/subscribe/notify)
extension ProximityBLE: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }

        print("didDiscoverServices:", peripheral.services?.map(\.uuid) ?? [])

        peripheral.services?.forEach {
            peripheral.discoverCharacteristics([charUUID], for: $0)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil else { return }
        
        print("didDiscoverCharacteristics:", service.characteristics?.map(\.uuid) ?? [])
        
        service.characteristics?.forEach { ch in
            guard ch.uuid == charUUID else { return }
            periphToChar[peripheral.identifier] = ch
            if ch.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: ch)
            }
            
            // ✅ mark this peer as ready to receive pings
            if let name = nameForPeripheralID[peripheral.identifier] {

                print("✅ \(name) is READY (char discovered)")
                DispatchQueue.main.async {
                    self.readyNames.insert(name)
                }
            }
            
            // Send a hello write (optional)
            if ch.properties.contains(.writeWithoutResponse) {
                let hello = ["name": UIDevice.current.name]
                if let data = try? JSONSerialization.data(withJSONObject: hello) {
                    peripheral.writeValue(data, for: ch, type: .withoutResponse)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        handleIncomingPayload(data, from: "notify")
    }
}

extension ProximityBLE {
    // Call this whenever we discover or update a peripheral
    func handleDiscovery(of peripheral: CBPeripheral, rssi: NSNumber) {
        let displayName = peripheral.name ?? peripheral.identifier.uuidString
        peers[displayName] = rssi.doubleValue
        nameToIdentifierMap[displayName] = peripheral.identifier.uuidString
    }
    
    // VM will use this to fetch a stable ID
    func identifier(forDisplayName displayName: String) -> String? {
        nameToIdentifierMap[displayName]
    }
}

final class MockBLEService: ProximityBLE {
    override init() {
        super.init()
    }
}
