import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        NavigationView {
            ZStack {
                contentListOrEmptyState
                bottomPinnedAddDevicesButton
            }
            .navigationTitle("Favorites List")
            .sheet(isPresented: $viewModel.isPresentingEditDetailsSheet) {
                if let device = viewModel.devicePendingNicknameEdit {
                    EditBluetoothDetailsView(
                        deviceIdentifier: device.deviceIdentifier,
                        originalDeviceName: device.deviceName ?? "Unknown",
                        userDefinedNicknameDraft: $viewModel.editableUserDefinedNicknameDraft,
                        onCancelTapped: {
                            viewModel.cancelNicknameEdit()
                        },
                        onSaveTapped: {
                            viewModel.commitNicknameEdit()
                        }
                    )
                }
            }
            .confirmationDialog(
                "Remove from Favorites?",
                isPresented: $viewModel.isPresentingRemovalConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    viewModel.confirmRemovalIfNeeded()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelRemoval()
                }
            } message: {
                if let device = viewModel.devicePendingRemoval {
                    Text("This will remove \(viewModel.displayName(for: device)) from your favorites.")
                }
            }
            .fullScreenCover(isPresented: $viewModel.isPresentingBluetoothScanner) {
                // Present your BLE scanner without affecting other screens.
                NavigationView {
                    BLEView(vm: BLEViewModel(service: ProximityBLE()))
                        .navigationTitle("Bluetooth Scanner")
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Back") {
                                    viewModel.dismissBluetoothScanner()
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            viewModel.reloadFavoriteBluetoothDevicesFromPersistentStore()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var contentListOrEmptyState: some View {
        if viewModel.favoriteBluetoothDevices.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 56, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text("No Favorite Devices")
                    .font(.headline)
                Text("Add your frequently used Bluetooth devices here for quick access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
            .padding(.top, 48)
        } else {
            List {
                ForEach(viewModel.favoriteBluetoothDevices) { device in
                    Button {
                        viewModel.beginEditingNickname(for: device)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.displayName(for: device))
                                .font(.headline)
                            Text(device.deviceIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .contextMenu {
                        Button {
                            viewModel.beginEditingNickname(for: device)
                        } label: {
                            Label("Edit Nickname", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            viewModel.requestRemovalConfirmation(for: device)
                        } label: {
                            Label("Remove from Favorites", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.requestRemovalConfirmation(for: device)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var bottomPinnedAddDevicesButton: some View {
        VStack {
            Spacer()
            // Pinned button above the safe area
            Button(action: { viewModel.presentBluetoothScanner() }) {
                HStack {
                    Image(systemName: "plus.viewfinder")
                    Text("Add New Devices")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 82)
            .accessibilityLabel("Add New Bluetooth Devices")
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
