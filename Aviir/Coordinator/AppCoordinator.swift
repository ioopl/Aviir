import SwiftUI

final class AppCoordinator: ObservableObject {
    enum Tab: Hashable {
        case home
        case bluetooth
        case uwb
        case settings
    }
    
    @Published var selectedTab: Tab = .bluetooth
    
    // DI: singletons for services (shared across VMs)
    let bleService = ProximityBLE()
    
    init() {
    }
}
