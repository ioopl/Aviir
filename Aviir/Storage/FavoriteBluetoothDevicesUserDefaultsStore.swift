import Foundation

/// Thin utility dedicated to persisting favorite devices using UserDefaults.
enum FavoriteBluetoothDevicesUserDefaultsStore {
    private static let favoritesDefaultsKey = "favorite_bluetooth_devices_v1"

    static func loadFavoriteDevices() -> [FavoriteBluetoothDevice] {
        guard
            let data = UserDefaults.standard.data(forKey: favoritesDefaultsKey),
            let decoded = try? JSONDecoder().decode([FavoriteBluetoothDevice].self, from: data)
        else { return [] }
        return decoded
    }

    static func saveFavoriteDevices(_ devices: [FavoriteBluetoothDevice]) {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(data, forKey: favoritesDefaultsKey)
    }

    static func updateOrInsertFavoriteDevice(_ device: FavoriteBluetoothDevice) -> [FavoriteBluetoothDevice] {
        var current = loadFavoriteDevices()
        if let index = current.firstIndex(where: { $0.deviceIdentifier == device.deviceIdentifier }) {
            current[index] = device
        } else {
            current.append(device)
        }
        saveFavoriteDevices(current)
        return current
    }

    static func removeFavoriteDevice(withIdentifier deviceIdentifier: String) -> [FavoriteBluetoothDevice] {
        var current = loadFavoriteDevices()
        current.removeAll { $0.deviceIdentifier == deviceIdentifier }
        saveFavoriteDevices(current)
        return current
    }
}
