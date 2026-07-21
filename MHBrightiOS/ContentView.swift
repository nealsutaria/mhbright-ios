import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        if authManager.isLoggedIn {
            NavigationStack {
                HomeView()
                    .environmentObject(authManager)
            }
        } else {
            NavigationStack {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
