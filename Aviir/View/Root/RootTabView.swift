import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    let mainViewModel: MainViewModel

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            
            MainView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                        .accessibilityLabel("Home tab")
                        .accessibilityHint("Shows your main dashboard view.")
                        .accessibilityAddTraits(.isButton)
                }.tag(AppCoordinator.Tab.home)
            
            BLEView(vm: BLEViewModel(service: coordinator.bleService))
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .accessibilityLabel("Bluetooth radar tab")
                        .accessibilityHint("Shows nearby Bluetooth devices on the radar.")
                        .accessibilityAddTraits(.isButton)
                }
                .tag(AppCoordinator.Tab.bluetooth)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("Settings tab")
                        .accessibilityHint("Adjust app preferences and connectivity options.")
                        .accessibilityAddTraits(.isButton)
                }
                .tag(AppCoordinator.Tab.settings)
        }
    }
}

#Preview {
    RootTabView(mainViewModel: MainViewModel())
}
