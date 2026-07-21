import Foundation

@MainActor
class AuthManager: ObservableObject {
    @Published var token: String?
    @Published var userEmail: String?

    private let tokenKey = "mhbright_api_token"
    private let emailKey = "mhbright_user_email"

    init() {
        self.token = KeychainManager.read(for: tokenKey)
        self.userEmail = UserDefaults.standard.string(forKey: emailKey)
    }

    var isLoggedIn: Bool {
        token != nil
    }

    func login(email: String, password: String) async throws {
        let response = try await APIClient.shared.login(email: email, password: password)

        saveAuthSession(
            token: response.token,
            email: response.user.email
        )
    }

    func signup(email: String, password: String, passwordConfirmation: String) async throws {
        let response = try await APIClient.shared.signup(
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation
        )

        saveAuthSession(
            token: response.token,
            email: response.user.email
        )
    }

    func loginWithGoogle(idToken: String) async throws {
        let response = try await APIClient.shared.googleLogin(idToken: idToken)

        saveAuthSession(
            token: response.token,
            email: response.user.email
        )
    }

    func logout() async {
        let currentToken = token

        if let currentToken {
            do {
                try await APIClient.shared.logout(token: currentToken)
            } catch {
                print("Server logout failed:")
                print(error)
            }
        }

        clearAuthSession()
    }

    private func saveAuthSession(token: String, email: String) {
        self.token = token
        self.userEmail = email

        KeychainManager.save(token, for: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
    }

    private func clearAuthSession() {
        self.token = nil
        self.userEmail = nil

        KeychainManager.delete(for: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }
}
