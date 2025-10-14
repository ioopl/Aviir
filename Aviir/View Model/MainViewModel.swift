import Foundation
import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: - Published State

    @Published var favoriteBluetoothDevices: [FavoriteBluetoothDevice] = []
    @Published var isPresentingBluetoothScanner: Bool = false
    @Published var isPresentingEditDetailsSheet: Bool = false
    @Published var devicePendingNicknameEdit: FavoriteBluetoothDevice?
    @Published var isPresentingRemovalConfirmationDialog: Bool = false
    @Published var devicePendingRemoval: FavoriteBluetoothDevice?

    // This is bound to the TextField inside the edit sheet.
    @Published var editableUserDefinedNicknameDraft: String = ""

    // MARK: - Lifecycle

    init() {
        reloadFavoriteBluetoothDevicesFromPersistentStore()
    }

    // MARK: - Loading / Saving

    func reloadFavoriteBluetoothDevicesFromPersistentStore() {
        favoriteBluetoothDevices = FavoriteBluetoothDevicesUserDefaultsStore.loadFavoriteDevices()
            .sorted { lhs, rhs in
                let l = (lhs.userDefinedNickname ?? lhs.deviceName ?? "").lowercased()
                let r = (rhs.userDefinedNickname ?? rhs.deviceName ?? "").lowercased()
                return l < r
            }
    }

    // MARK: - Editing Nicknames

    func beginEditingNickname(for device: FavoriteBluetoothDevice) {
        devicePendingNicknameEdit = device
        editableUserDefinedNicknameDraft = device.userDefinedNickname ?? device.deviceName ?? ""
        isPresentingEditDetailsSheet = true
    }

    func commitNicknameEdit() {
        guard var device = devicePendingNicknameEdit else { return }
        let trimmed = editableUserDefinedNicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        device.userDefinedNickname = trimmed.isEmpty ? nil : trimmed
        favoriteBluetoothDevices = FavoriteBluetoothDevicesUserDefaultsStore.updateOrInsertFavoriteDevice(device)
            .sorted { ($0.userDefinedNickname ?? $0.deviceName ?? "") < ($1.userDefinedNickname ?? $1.deviceName ?? "") }
        isPresentingEditDetailsSheet = false
        devicePendingNicknameEdit = nil
    }

    func cancelNicknameEdit() {
        isPresentingEditDetailsSheet = false
        devicePendingNicknameEdit = nil
        editableUserDefinedNicknameDraft = ""
    }

    // MARK: - Removal

    func requestRemovalConfirmation(for device: FavoriteBluetoothDevice) {
        devicePendingRemoval = device
        isPresentingRemovalConfirmationDialog = true
    }

    func confirmRemovalIfNeeded() {
        guard let device = devicePendingRemoval else { return }
        favoriteBluetoothDevices = FavoriteBluetoothDevicesUserDefaultsStore.removeFavoriteDevice(withIdentifier: device.deviceIdentifier)
            .sorted { ($0.userDefinedNickname ?? $0.deviceName ?? "") < ($1.userDefinedNickname ?? $1.deviceName ?? "") }
        isPresentingRemovalConfirmationDialog = false
        devicePendingRemoval = nil
    }

    func cancelRemoval() {
        isPresentingRemovalConfirmationDialog = false
        devicePendingRemoval = nil
    }

    // MARK: - Navigation

    func presentBluetoothScanner() {
        isPresentingBluetoothScanner = true
    }

    func dismissBluetoothScanner() {
        isPresentingBluetoothScanner = false
    }

    // MARK: - Helpers

    func displayName(for device: FavoriteBluetoothDevice) -> String {
        device.userDefinedNickname?.isEmpty == false
            ? device.userDefinedNickname!
            : (device.deviceName ?? "Unnamed Device")
    }
}
