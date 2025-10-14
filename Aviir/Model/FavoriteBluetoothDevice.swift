import Foundation

/// A persistable representation of a Bluetooth device the user marked as favorite.
struct FavoriteBluetoothDevice: Identifiable, Codable, Equatable {
    /// Use the Bluetooth device identifier (e.g., UUID string) as the stable id.
    var id: String { deviceIdentifier }

    /// System or advertised name we saw from the device (optional if unknown).
    var deviceName: String?

    /// A user-defined nickname that overrides `deviceName` if present.
    var userDefinedNickname: String?

    /// The unique Bluetooth identifier (e.g., CBPeripheral.identifier UUID string).
    let deviceIdentifier: String
}
