import SwiftUI

struct EditBluetoothDetailsView: View {

    let deviceIdentifier: String
    let originalDeviceName: String

    @Binding var userDefinedNicknameDraft: String

    let onCancelTapped: () -> Void
    let onSaveTapped: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device")) {
                    HStack {
                        Text("Identifier")
                        Spacer()
                        Text(deviceIdentifier)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                    HStack {
                        Text("Original Name")
                        Spacer()
                        Text(originalDeviceName)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                }

                Section(header: Text("Nickname")) {
                    TextField("Enter a nickname", text: $userDefinedNicknameDraft)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                }
            }
            .navigationTitle("Edit Bluetooth Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancelTapped)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSaveTapped)
                        .disabled(userDefinedNicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
