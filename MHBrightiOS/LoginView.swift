import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggingIn = false

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
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthManager())
    }
}
