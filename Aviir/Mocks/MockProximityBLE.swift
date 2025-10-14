import Foundation
import Combine

/// Mock CoreBluetooth-free service, It mirrors real ProximityBLE API but only uses timers and in-memory data.
/// A preview- and simulator-safe stand-in for the real BLE service.
/// No CoreBluetooth imports; publishes fake peers, pingedNames, and readyNames.
final class MockProximityBLE {
    // Match the published interface your BLEViewModel expects.
    @Published var peers: [String: Double] = [:]             // name -> RSSI
    @Published var pingedNames: Set<String> = []             // currently "pulsing" peers
    @Published var readyNames: Set<String> = []              // peers considered "connected/ready"

    // Internal demo timer to wiggle RSSIs & auto-toggle ping effects in previews.
    private var demoTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(seedDemoData: Bool = true) {
        if seedDemoData {
            seedInitialDemoPeers()
            startDemoTimerForAnimatedPreviews()
        }
    }

    deinit { demoTimer?.invalidate() }

    // MARK: - Preview/Demo Controls

    func seedInitialDemoPeers() {
        // Stable starting RSSIs (closer = less negative)
        peers = [
            "Umair-iPhone" : -47.0,
            "Test-iPad"    : -73.0,
            "MacBook-Air"  : -84.0
        ]
        readyNames = ["Umair-iPhone", "Test-iPad"] // show some as connected
    }

    func startDemoTimerForAnimatedPreviews() {
        demoTimer?.invalidate()
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            // Gently wiggle RSSIs to make the radar feel alive.
            for key in peers.keys {
                if var rssi = peers[key] {
                    let delta = Double(Int.random(in: -2...2))
                    rssi = max(-95, min(-40, rssi + delta))
                    peers[key] = rssi
                }
            }
            // Randomly toggle a "ping" visual for fun.
            if let randomName = peers.keys.randomElement() {
                sendPing(to: randomName)
                // Auto-clear ping effect shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.pingedNames.remove(randomName)
                }
            }
        }
    }

    // MARK: - API Surface to Match the Real Service

    /// In the real service, this would transmit a BLE packet.
    func sendPing(to name: String) {
        pingedNames.insert(name)
    }

    /// In the real service you’d return a peripheral UUID; here we fake a stable identifier.
    func identifier(forDisplayName displayName: String) -> String? {
        // Deterministic pseudo-UUID from the name for previews
        let base = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!.uuidString
        return base + "-" + String(abs(displayName.hashValue % 10_000))
    }
}
