import Foundation

@MainActor
class AuthManager: ObservableObject {
    @Published var token: String?
    @Published var userEmail: String?

    var isLoggedIn: Bool {
        token != nil
    }

    func login(email: String, password: String) async throws {
        let response = try await APIClient.shared.login(email: email, password: password)

        self.token = response.token
        self.userEmail = response.user.email
    }

    func logout() {
        self.token = nil
        self.userEmail = nil
    }
}
