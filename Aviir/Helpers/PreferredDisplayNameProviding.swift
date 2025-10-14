/// Get a dynamic display name
/// Create a tiny abstraction so we can swap where the name comes from:

import Foundation
import UIKit

protocol PreferredDisplayNameProviding {
    func preferredDisplayName() -> String
}

/// Default: use the device’s system/Bluetooth name (what we see in Settings > General > About > Name)
struct SystemDeviceNameProvider: PreferredDisplayNameProviding {
    func preferredDisplayName() -> String {
        UIDevice.current.name   // e.g. "Umair’s iPhone"
    }
}

/// Optional: we can use Bluetooth service if we want to keep a custom local name there
struct BLEServiceNameProvider: PreferredDisplayNameProviding {
    let bleService: ProximityBLE
    func preferredDisplayName() -> String {
        bleService.readyNames.first ?? UIDevice.current.name
    }
}
