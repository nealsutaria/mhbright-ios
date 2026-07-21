import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var isSigningUp = false
    @State private var isGoogleSigningUp = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $passwordConfirmation)
                    .textFieldStyle(.roundedBorder)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await signup()
                }
            } label: {
                if isSigningUp {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(isSigningUp || email.isEmpty || password.isEmpty || passwordConfirmation.isEmpty)

            VStack(spacing: 12) {
                Text("or")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Create account with Google")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    Task {
                        await signUpWithGoogle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("G")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.blue)
                            .frame(width: 24, height: 24)

                        Text("Sign up with Google")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .disabled(isGoogleSigningUp)
            }

            Button("Already have an account? Log In") {
                dismiss()
            }
            .font(.footnote)

            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signup() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return
        }

        guard password == passwordConfirmation else {
            errorMessage = "Passwords do not match."
            return
        }

        isSigningUp = true
        errorMessage = ""

        do {
            try await authManager.signup(
                email: trimmedEmail,
                password: password,
                passwordConfirmation: passwordConfirmation
            )

            dismiss()
        } catch {
            errorMessage = "Could not create account."
            print(error)
        }

        isSigningUp = false
    }

    private func signUpWithGoogle() async {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            errorMessage = "Could not open Google Sign-In."
            return
        }

        isGoogleSigningUp = true
        errorMessage = ""

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Could not get Google ID token."
                isGoogleSigningUp = false
                return
            }

            try await authManager.loginWithGoogle(idToken: idToken)
            dismiss()
        } catch {
            errorMessage = "Google sign up failed."
            print(error)
        }

        isGoogleSigningUp = false
    }
}

#Preview {
    NavigationStack {
        SignupView()
            .environmentObject(AuthManager())
    }
}
