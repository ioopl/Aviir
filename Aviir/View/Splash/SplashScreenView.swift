import SwiftUI

struct SplashScreenView: View {
    @ObservedObject var viewModel: SplashScreenViewModel

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            ZStack {
                Circle()
                    .trim(from: 0.0, to: viewModel.circularStrokeTrimProgress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90)) // start at top
                    .frame(width: 220, height: 220)
                    .accessibilityHidden(true)

                Text(viewModel.userFullName)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 24)
                    .frame(width: 220 * 0.82)
                    .accessibilityLabel(Text("Welcome \(viewModel.userFullName)"))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: viewModel.splashAnimationDurationInSeconds)) {
                viewModel.circularStrokeTrimProgress = 1.0
            }
            viewModel.beginSplashAnimation()
        }
    }
}

#Preview {
    SplashScreenView(viewModel: SplashScreenViewModel(userFullName: "Hello", splashAnimationDurationInSeconds: 3.0, onSplashAnimationCompleted: {
        
    }))
}
