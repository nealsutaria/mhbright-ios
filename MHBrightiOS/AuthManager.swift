import Foundation

@MainActor
class AuthManager: ObservableObject {
    @Published var token: String?
    @Published var userEmail: String?

    private let tokenKey = "mhbright_api_token"
    private let emailKey = "mhbright_user_email"

    init() {
        self.token = UserDefaults.standard.string(forKey: tokenKey)
        self.userEmail = UserDefaults.standard.string(forKey: emailKey)
    }

    var isLoggedIn: Bool {
        token != nil
    }

    func login(email: String, password: String) async throws {
        let response = try await APIClient.shared.login(email: email, password: password)

        self.token = response.token
        self.userEmail = response.user.email

        UserDefaults.standard.set(response.token, forKey: tokenKey)
        UserDefaults.standard.set(response.user.email, forKey: emailKey)
    }
    
    func signup(email: String, password: String, passwordConfirmation: String) async throws {
        let response = try await APIClient.shared.signup(
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation
        )

        self.token = response.token
        self.userEmail = response.user.email

        UserDefaults.standard.set(response.token, forKey: tokenKey)
        UserDefaults.standard.set(response.user.email, forKey: emailKey)
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

        self.token = nil
        self.userEmail = nil

        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }
    
    func loginWithGoogle(idToken: String) async throws {
        let response = try await APIClient.shared.googleLogin(idToken: idToken)

        self.token = response.token
        self.userEmail = response.user.email

        UserDefaults.standard.set(response.token, forKey: tokenKey)
        UserDefaults.standard.set(response.user.email, forKey: emailKey)
    }
}
