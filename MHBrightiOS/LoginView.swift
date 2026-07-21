import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggingIn = false
    @State private var isGoogleLoggingIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("MHBright")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your health records, smarter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await login()
                }
            } label: {
                if isLoggingIn {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.indigo)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isLoggingIn || email.isEmpty || password.isEmpty)

            VStack(spacing: 12) {
                Text("or")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Text("Continue with Google")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                GoogleSignInButton {
                    Task {
                        await signInWithGoogle()
                    }
                }
                .frame(height: 50)
                .disabled(isGoogleLoggingIn)
            }

            NavigationLink {
                SignupView()
                    .environmentObject(authManager)
            } label: {
                Text("Don't have an account? Sign Up")
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
    }

    private func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }

        isLoggingIn = true
        errorMessage = ""

        do {
            try await authManager.login(email: trimmedEmail, password: password)
        } catch {
            errorMessage = "Login failed. Check your email and password."
            print(error)
        }

        isLoggingIn = false
    }

    private func signInWithGoogle() async {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            errorMessage = "Could not open Google Sign-In."
            return
        }

        isGoogleLoggingIn = true
        errorMessage = ""

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Could not get Google ID token."
                isGoogleLoggingIn = false
                return
            }

            try await authManager.loginWithGoogle(idToken: idToken)
        } catch {
            errorMessage = "Google login failed."
            print(error)
        }

        isGoogleLoggingIn = false
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthManager())
    }
}
