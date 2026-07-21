import SwiftUI

struct CopilotView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AppointmentBriefsListView()
                        .environmentObject(authManager)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Appointment Briefs")
                            .font(.headline)

                        Text("Generate doctor visit prep notes from your saved health memories.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    HealthInsightsView()
                        .environmentObject(authManager)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Health Insights")
                            .font(.headline)

                        Text("View patterns and follow-up observations found across your records.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Copilot")
    }
}

#Preview {
    NavigationStack {
        CopilotView()
            .environmentObject(AuthManager())
    }
}
