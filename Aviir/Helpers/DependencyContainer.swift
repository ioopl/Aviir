final class DependencyContainer {
    // Swap this to BLEServiceNameProvider if/when you have it:
    let preferredDisplayNameProvider: PreferredDisplayNameProviding = SystemDeviceNameProvider()

    // Shared services:
    // let bleService = ProximityBLE()
}
