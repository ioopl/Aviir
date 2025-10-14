import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    let mainViewModel: MainViewModel

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            
            MainView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    //Text("Main")
                }.tag(AppCoordinator.Tab.home)
            
            BLEView(vm: BLEViewModel(service: coordinator.bleService))
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    //Text("BLE")
                }
                .tag(AppCoordinator.Tab.bluetooth)
            /*
            UWBView(vm: UWBViewModel(uwb: coordinator.uwbService, connector: coordinator.peerConnector))
                .tabItem {
                    Image(systemName: "wave.3.right") // or "location.north.line"
                    Text("UWB")
                }
                .tag(AppCoordinator.Tab.uwb)
            */
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(AppCoordinator.Tab.settings)
        }
    }
}

#Preview {
    RootTabView(mainViewModel: MainViewModel())
}
