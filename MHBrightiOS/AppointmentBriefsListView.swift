import SwiftUI

struct AppointmentBriefsListView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var appointmentBriefs: [AppointmentBrief] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showNewBriefSheet = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading appointment briefs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appointmentBriefs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)

                    Text("No appointment briefs yet")
                        .font(.headline)

                    Text("Create a brief to prepare for a doctor visit using your saved health memories.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        showNewBriefSheet = true
                    } label: {
                        Text("Create Brief")
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appointmentBriefs) { brief in
                        NavigationLink {
                            AppointmentBriefDetailView(briefId: brief.id) { deletedId in
                                appointmentBriefs.removeAll { $0.id == deletedId }
                            }
                            .environmentObject(authManager)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(brief.title ?? "Appointment Brief")
                                    .font(.headline)

                                Text(brief.topic ?? "No topic")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Copilot")
        .toolbar {
            Button {
                showNewBriefSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showNewBriefSheet) {
            NavigationStack {
                NewAppointmentBriefView { newBrief in
                    appointmentBriefs.insert(newBrief, at: 0)
                }
                .environmentObject(authManager)
            }
        }
        .task {
            await loadAppointmentBriefs()
        }
        .overlay {
            if !errorMessage.isEmpty {
                VStack {
                    Spacer()

                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding()
                }
            }
        }
    }

    private func loadAppointmentBriefs() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            appointmentBriefs = try await APIClient.shared.fetchAppointmentBriefs(token: token)
        } catch {
            errorMessage = "Could not load appointment briefs."
            print(error)
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AppointmentBriefsListView()
            .environmentObject(AuthManager())
    }
}
