import SwiftUI

struct BLEView: View {
    @ObservedObject var vm: BLEViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Banner if Bluetooth itself is off
            if vm.isBluetoothOff {
                Label("Bluetooth is Off. Turn it on to scan for devices.", systemImage: "bolt.horizontal.circle")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.yellow.opacity(0.12))
            }
            
            Section {
                HStack {
                    Spacer()
                    RadarBLEView(
                        peers: vm.peers,
                        pingedNames: vm.pingedNames,
                        onPing: { name in vm.sendPing(to: name) },
                        readyNames: vm.readyNames
                    )
                    .frame(height: 260)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text("Discovered Devices")) {
                if vm.peers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No devices found")
                            .font(.headline)
                        Text("Keep the other device awake and nearby.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                } else {
                    ForEach(vm.peers.keys.sorted(), id: \.self) { name in
                        let isReady = vm.readyNames.contains(name)
                        let identifier = vm.identifierForDisplayName(name)
                        let rssi = vm.peers[name]
                        
                        DeviceRowView(
                            displayName: shortLabel(name),
                            isReady: isReady,
                            identifierString: identifier,
                            rssiValue: rssi,
                            onPingTapped: { vm.sendPing(to: name) },
                            isFavorited: vm.isDeviceFavorited(named: name),
                            onFavoriteTapped: {
                                if vm.isDeviceFavorited(named: name) {
                                    vm.requestRemovalForFavorite(named: name)
                                } else {
                                    vm.requestAddToFavorites(named: name)
                                }
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if vm.isDeviceFavorited(named: name) {
                                Button(role: .destructive) {
                                    vm.requestRemovalForFavorite(named: name)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            
                            if vm.isDeviceFavorited(named: name) {
                                vm.requestRemovalForFavorite(named: name)
                            } else {
                                vm.requestAddToFavorites(named: name)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        // Alert shown when permission previously denied
        .alert("Bluetooth Permission Needed",
               isPresented: $vm.isShowingBluetoothSettingsAlert,
               actions: {
            Button("Open Settings") { vm.openSystemSettings() }
            Button("Not Now", role: .cancel) {}
        },
               message: {
            Text("This app uses Bluetooth to discover nearby phones and show them on the radar. Please enable Bluetooth access in Settings.")
        })
        .onAppear {
            vm.evaluateAndShowSettingsAlertOnAppear()
        }

        // Add favorite (with optional nickname)
        .sheet(isPresented: $vm.isPresentingAddFavoriteSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Nickname (optional)")) {
                        TextField("Enter a nickname", text: $vm.nicknameDraftForFavorite)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                    }
                }
                .navigationTitle("Add to Favorites")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { vm.cancelAddFavorite() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { vm.commitAddFavorite() }
                    }
                }
            }
        }
        // Remove confirmation
        .confirmationDialog(
            "Remove from Favorites?",
            isPresented: $vm.isPresentingRemovalConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { vm.confirmRemovalIfNeeded() }
            Button("Cancel", role: .cancel) { vm.cancelRemoval() }
        } message: {
            Text("This device will be removed from your favorites.")
        }
        .onAppear { vm.reloadFavoritesFromPersistentStore() }
    }
}

// MARK: - Row

private struct DeviceRowView: View {
    let displayName: String
    let isReady: Bool
    let identifierString: String
    let rssiValue: Double?
    let onPingTapped: () -> Void

    let isFavorited: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Name + Ready + Actions
            HStack(spacing: 8) {
                Text(displayName)
                    .font(.headline)

                if isReady {
                    Text("Ready")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("Syncing…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onFavoriteTapped) {
                    if isFavorited {
                        Image(systemName: "star.fill").accessibilityLabel("Tap to remove from Favorites")
                    } else {
                        Image(systemName: "star").accessibilityLabel("Tap to add to Favorites")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isFavorited ? .yellow : .accentColor) // yellow for favorited
            }

            // Second row: identifier + RSSI
            HStack(spacing: 12) {
                Label(identifierString, systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let rssi = rssiValue {
                    Label("\(Int(rssi)) dBm", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 12, content: {
                Button("Ping", action: onPingTapped)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isReady)
            })
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Utilities

private func shortLabel(_ s: String) -> String {
    if s.contains("-") { return String(s.prefix(8)) }
    if let first = s.split(separator: " ").first { return String(first.prefix(12)) }
    return String(s.prefix(12))
}

// MARK: - Preview

#Preview("Full BLE Screen Example") {
    // Create a fake service and view model
    let mockService = MockBLEService()
    let mockViewModel = BLEViewModel(service: mockService)
    
    // Seed some fake data
    mockViewModel.peers = [
        "Umair-iPhone": -47.0,
        "Test-iPad": -75.0,
        "MacBook-Air": -83.0
    ]
    mockViewModel.readyNames = ["Umair-iPhone", "Test-iPad"]
    
    return NavigationView {
        BLEView(vm: mockViewModel)
    }
}

