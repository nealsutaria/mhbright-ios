import SwiftUI
import GoogleSignIn

@main
struct MHBrightiOSApp: App {
    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: GoogleConfig.clientID
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
