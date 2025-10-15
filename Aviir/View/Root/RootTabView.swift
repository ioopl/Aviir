import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    let mainViewModel: MainViewModel

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            
            MainView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                }.tag(AppCoordinator.Tab.home)
            
            BLEView(vm: BLEViewModel(service: coordinator.bleService))
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                }
                .tag(AppCoordinator.Tab.bluetooth)
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                }
                .tag(AppCoordinator.Tab.settings)
        }
    }
}

#Preview {
    RootTabView(mainViewModel: MainViewModel())
}
