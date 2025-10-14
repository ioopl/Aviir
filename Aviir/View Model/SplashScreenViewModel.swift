import Foundation
import Combine

@MainActor
final class SplashScreenViewModel: ObservableObject {
    @Published var circularStrokeTrimProgress: CGFloat = 0.0
    let userFullName: String
    let splashAnimationDurationInSeconds: TimeInterval
    private let onSplashAnimationCompleted: () -> Void

    init(userFullName: String,
         splashAnimationDurationInSeconds: TimeInterval,
         onSplashAnimationCompleted: @escaping () -> Void) {
        self.userFullName = userFullName
        self.splashAnimationDurationInSeconds = splashAnimationDurationInSeconds
        self.onSplashAnimationCompleted = onSplashAnimationCompleted
    }

    func beginSplashAnimation() {
        // advance the trim to 1.0 over the specified duration (handled by the View animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + splashAnimationDurationInSeconds) {
            self.onSplashAnimationCompleted()
        }
    }
}
