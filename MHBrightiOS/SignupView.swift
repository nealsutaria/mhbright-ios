import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var isSigningUp = false
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
}

#Preview {
    NavigationStack {
        SignupView()
            .environmentObject(AuthManager())
    }
}
