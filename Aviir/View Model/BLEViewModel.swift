import Foundation
import UIKit
import CoreBluetooth
import Combine

@MainActor
final class BLEViewModel: ObservableObject {
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
    
    // UI To be handled by the View Model
    @Published private(set) var favoriteDeviceIdentifiers: Set<String> = []
    @Published var isPresentingAddFavoriteSheet: Bool = false
    @Published var isPresentingRemovalConfirmationDialog: Bool = false
    @Published var nicknameDraftForFavorite: String = ""
    @Published private(set) var devicePendingFavoriteName: String?
    @Published private(set) var devicePendingRemovalIdentifier: String?
    
    // Bluetooth state + authorization mirror properties
    @Published private(set) var bluetoothManagerState: CBManagerState = .unknown
    @Published private(set) var bluetoothAuthorizationStatus: CBManagerAuthorization = CBCentralManager.authorization

    // To Control the alert in the View
    @Published var isShowingBluetoothSettingsAlert: Bool = false

    // Convenience flag the View use
    var isBluetoothDeniedOrRestricted: Bool {
        switch bluetoothAuthorizationStatus {
        case .denied, .restricted: return true
        default: return false
        }
    }

    var isBluetoothOff: Bool {
        bluetoothManagerState != .poweredOn
    }

    private let service: ProximityBLE
    private var cancellables = Set<AnyCancellable>()
    
    init(service: ProximityBLE) {
        self.service = service
        
        // Mirror the service's @Published properties into the VM
        service.$peers
            .receive(on: DispatchQueue.main)
            .assign(to: \.peers, on: self)
            .store(in: &cancellables)
        
        service.$pingedNames
            .receive(on: DispatchQueue.main)
            .assign(to: \.pingedNames, on: self)
            .store(in: &cancellables)
        
        service.$readyNames
            .receive(on: DispatchQueue.main)
            .assign(to: \.readyNames, on: self)
            .store(in: &cancellables)
        
        // Bluetooth Permission States
        service.$bluetoothManagerState
            .receive(on: DispatchQueue.main)
            .assign(to: \.bluetoothManagerState, on: self)
            .store(in: &cancellables)
        
        service.$bluetoothAuthorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.bluetoothAuthorizationStatus, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Intents
    
    func sendPing(to name: String) {
        service.sendPing(to: name)
    }
    
    
    func identifierForDisplayName(_ name: String) -> String {
        service.identifier(forDisplayName: name) ?? name // fallback
    }
    
    func isDeviceFavorited(named name: String) -> Bool {
        favoriteDeviceIdentifiers.contains(identifierForDisplayName(name))
    }
    
    func requestAddToFavorites(named name: String) {
        devicePendingFavoriteName = name
        nicknameDraftForFavorite = name
        isPresentingAddFavoriteSheet = true
    }
    
    func commitAddFavorite() {
        guard let name = devicePendingFavoriteName else { return }
        let id = identifierForDisplayName(name)
        let model = FavoriteBluetoothDevice(
            deviceName: name,
            userDefinedNickname: nicknameDraftForFavorite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : nicknameDraftForFavorite.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceIdentifier: id
        )
        _ = FavoriteBluetoothDevicesUserDefaultsStore.updateOrInsertFavoriteDevice(model)
        reloadFavoritesFromPersistentStore()
        // reset
        isPresentingAddFavoriteSheet = false
        devicePendingFavoriteName = nil
        nicknameDraftForFavorite = ""
    }
    
    func cancelAddFavorite() {
        isPresentingAddFavoriteSheet = false
        devicePendingFavoriteName = nil
        nicknameDraftForFavorite = ""
    }
    
    func requestRemovalForFavorite(named name: String) {
        let id = identifierForDisplayName(name)
        devicePendingRemovalIdentifier = id
        isPresentingRemovalConfirmationDialog = true
    }
    
    func confirmRemovalIfNeeded() {
        guard let id = devicePendingRemovalIdentifier else { return }
        _ = FavoriteBluetoothDevicesUserDefaultsStore.removeFavoriteDevice(withIdentifier: id)
        reloadFavoritesFromPersistentStore()
        isPresentingRemovalConfirmationDialog = false
        devicePendingRemovalIdentifier = nil
    }
    
    func cancelRemoval() {
        isPresentingRemovalConfirmationDialog = false
        devicePendingRemovalIdentifier = nil
    }
    
    // MARK: - Persistence
    
    func reloadFavoritesFromPersistentStore() {
        let favorites = FavoriteBluetoothDevicesUserDefaultsStore.loadFavoriteDevices()
        favoriteDeviceIdentifiers = Set(favorites.map { $0.deviceIdentifier })
    }
    
    // MARK: - Bluetooth permission
    
    func evaluateAndShowSettingsAlertOnAppear() {
        if isBluetoothDeniedOrRestricted {
            isShowingBluetoothSettingsAlert = true
        }
    }
    
    // MARK: - Settings
    
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
