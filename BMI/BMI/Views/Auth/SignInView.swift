import AuthenticationServices
import SwiftData
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            BMIScreenBackground()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 20) {
                    BMILayerMark(width: 200)

                    VStack(spacing: 10) {
                        Text("The Big Mac Index")
                            .font(BMITypography.display(34))
                            .foregroundStyle(Color.bmiInk)
                            .multilineTextAlignment(.center)

                        Text("Track prices and quality worldwide.")
                            .font(BMITypography.ui(.subheadline))
                            .foregroundStyle(Color.bmiMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        authService.prepareSignInRequest(request)
                    } onCompletion: { result in
                        authService.handleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(Capsule())

                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .font(BMITypography.ui(.caption))
                            .foregroundStyle(Color.bmiRed)
                            .multilineTextAlignment(.center)
                    }

                    Text("Your Apple ID identifies your reports. Name and email are only shared on first sign-in.")
                        .font(BMITypography.ui(.caption2))
                        .foregroundStyle(Color.bmiMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    #if DEBUG
                    Button("Continue with Preview Account") {
                        authService.signInAsPreviewUser(in: modelContext)
                    }
                    .font(BMITypography.ui(.caption, weight: .semibold))
                    .foregroundStyle(Color.bmiInk)
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService())
        .modelContainer(PreviewData.previewContainer)
}
