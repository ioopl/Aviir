import SwiftUI

struct RadarBLEView: View {
    let peers: [String: Double]         // name -> RSSI
    let pingedNames: Set<String>        // names currently pulsing
    let onPing: (String) -> Void        // action to send ping
    var readyNames: Set<String> = []

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let R = size / 2
                ZStack {
                    Circle().stroke(style: StrokeStyle(lineWidth: 2, dash: [6,6])).opacity(0.25)
                    Circle().inset(by: R*0.33).stroke(style: StrokeStyle(lineWidth: 1, dash: [4,4])).opacity(0.2)
                    Circle().inset(by: R*0.66).stroke(style: StrokeStyle(lineWidth: 1, dash: [4,4])).opacity(0.2)

                    ForEach(peers.keys.sorted(), id: \.self) { key in
                        if let rssi = peers[key] {
                            let meters = min(approximateMeters(from: rssi), 15)
                            let radius = CGFloat(meters / 15.0) * R
                            let angle = angleForKey(key)
                            let x = radius * cos(angle), y = radius * sin(angle)
                            
                            // In this View, each dot checks: and if true it shows a "ripple" + grows the dot. That’s the visual change we see when a Ping comes in.
                            let pinged = pingedNames.contains(key)
                            let isReady = readyNames.contains(key)

                            ZStack {
                                if pinged {
                                    Circle()
                                        .stroke(lineWidth: 3)
                                        .opacity(0.5)
                                        .scaleEffect(1.5)
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.easeOut(duration: 0.6), value: pinged)
                                }
                                Circle()
                                    .frame(width: pinged ? 18 : 12, height: pinged ? 18 : 12)
                                    .scaleEffect(pinged ? 1.25 : 1.0)
                                    .animation(.easeOut(duration: 0.6), value: pinged)

                                Text(shortLabel(key))
                                    .font(.caption2).offset(y: -16)
                            }
                            .position(x: R + x, y: R - y)
                            .opacity(pinged ? 1.0 : (isReady ? 0.9 : 0.5))
                            .animation(.easeOut(duration: 0.6), value: pinged)

                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(height: 260)
        }
    }
}

private func shortLabel(_ s: String) -> String {
    if s.contains("-") { return String(s.prefix(8)) }
    if let first = s.split(separator: " ").first { return String(first.prefix(12)) }
    return String(s.prefix(12))
}

 /*
  What is RSSI?
 RSSI = Received Signal Strength Indicator
 It’s a number your phone measures for each BLE advertisement packet it receives.
 Typical range:
 −40 dBm → very strong signal (very close)
 −70 dBm → moderate distance
 −90 dBm → very weak (probably far or obstructed)
 In short: the higher (less negative) the RSSI, the closer the device.
 RSSI → approx distance
  */
    func approximateMeters(from rssi: Double) -> Double {
    let p0 = -59.0, n = 2.0
    return pow(10.0, (p0 - rssi) / (10.0 * n))
}

private func angleForKey(_ key: String) -> CGFloat {
    var hasher = Hasher(); hasher.combine(key)
    let frac = Double(abs(hasher.finalize() % 10_000)) / 10_000.0
    return CGFloat(frac * 2.0 * .pi)
}


#Preview("Radar BLE Example") {
    RadarBLEView(
        peers: [
            "Umair-iPhone": -47.0,
            "Test-iPad": -70.0,
            "MacBook-Air": -83.0
        ],
        pingedNames: ["Umair-iPhone"],
        onPing: { name in
            print("Pinged \(name)")
        },
        readyNames: ["Umair-iPhone", "Test-iPad"]
    )
    .frame(width: 320, height: 320)
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Radar BLE Example") {
    let mock = MockProximityBLE(seedDemoData: true)
    return RadarBLEView(
        peers: mock.peers,
        pingedNames: mock.pingedNames,
        onPing: { name in mock.sendPing(to: name) },
        readyNames: mock.readyNames
    )
    .frame(width: 320, height: 320)
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Radar - Empty State") {
    RadarBLEView(
        peers: [:],
        pingedNames: [],
        onPing: { _ in },
        readyNames: []
    )
    .frame(width: 320, height: 320)
    .padding()
}
