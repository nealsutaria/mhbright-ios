import SwiftUI

struct AppointmentBriefDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let briefId: Int
    let onDeleted: (Int) -> Void

    @State private var brief: AppointmentBrief?
    @State private var isLoading = false
    @State private var isRegenerating = false
    @State private var isDeleting = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading brief...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let brief {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(brief.title ?? "Appointment Brief")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let topic = brief.topic, !topic.isEmpty {
                            Text("Topic: \(topic)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        Text(brief.content ?? "No content.")
                            .font(.body)
                            .textSelection(.enabled)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Brief not found.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Brief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task {
                        await regenerateBrief()
                    }
                } label: {
                    if isRegenerating {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRegenerating || brief == nil)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(isDeleting || brief == nil)
            }
        }
        .alert("Delete Brief?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteBrief()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This appointment brief will be permanently deleted.")
        }
        .task {
            await loadBrief()
        }
    }

    private func loadBrief() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            brief = try await APIClient.shared.fetchAppointmentBrief(
                id: briefId,
                token: token
            )
        } catch {
            errorMessage = "Could not load brief."
            print(error)
        }

        isLoading = false
    }

    private func regenerateBrief() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isRegenerating = true
        errorMessage = ""

        do {
            brief = try await APIClient.shared.regenerateAppointmentBrief(
                id: briefId,
                token: token
            )
        } catch {
            errorMessage = "Could not regenerate brief."
            print(error)
        }

        isRegenerating = false
    }

    private func deleteBrief() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isDeleting = true
        errorMessage = ""

        do {
            try await APIClient.shared.deleteAppointmentBrief(
                id: briefId,
                token: token
            )

            onDeleted(briefId)
            dismiss()
        } catch {
            errorMessage = "Could not delete brief."
            print(error)
        }

        isDeleting = false
    }
}

#Preview {
    NavigationStack {
        AppointmentBriefDetailView(briefId: 1, onDeleted: { _ in })
            .environmentObject(AuthManager())
    }
}
