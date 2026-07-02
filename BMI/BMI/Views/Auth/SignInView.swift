import AuthenticationServices
import SwiftData
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            BMIGradient.header
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    Text("🍔")
                        .font(.system(size: 72))

                    Text("The Big Mac Index")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Track Big Mac prices and quality worldwide. Sign in to submit reports and compare the index in your currency.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        authService.prepareSignInRequest(request)
                    } onCompletion: { result in
                        authService.handleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                    }

                    Text("Your Apple ID is used to identify your reports. Name and email are only shared on first sign-in.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    #if DEBUG
                    Button("Continue with Preview Account") {
                        authService.signInAsPreviewUser(in: modelContext)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
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
