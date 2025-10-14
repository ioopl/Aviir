import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("About")) {
                Text("Aviir")
                Text("Uses Bluetooth for discovery & messaging")
            }
            Section(header: Text("Privacy")) {
                Text("App use Bluetooth for nearby discovery, \nUWB for precise ranging, and \nLocal Network (Bonjour) for peer discovery.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}
