import SwiftUI

@main
struct AviirApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @State private var isShowingSplashScreen: Bool = true

    private let dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView(mainViewModel: MainViewModel())
                    .environmentObject(coordinator)
                    .opacity(isShowingSplashScreen ? 0 : 1)

                if isShowingSplashScreen {
                    SplashScreenView(viewModel: SplashScreenViewModel(userFullName:  dependencies.preferredDisplayNameProvider.preferredDisplayName(), splashAnimationDurationInSeconds: 2.0, onSplashAnimationCompleted: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowingSplashScreen = false
                        }
                    }))
                    .transition(.opacity)
                }
            }
        }
    }
}
