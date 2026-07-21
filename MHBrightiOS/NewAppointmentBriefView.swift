import SwiftUI

struct NewAppointmentBriefView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: (AppointmentBrief) -> Void

    @State private var topic = ""
    @State private var isCreating = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Appointment Topic") {
                TextField("Example: hair loss and thyroid", text: $topic, axis: .vertical)
                    .lineLimit(1...3)

                Text("The Copilot will search your saved health memories and create a doctor visit prep brief.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await createBrief()
                    }
                } label: {
                    if isCreating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Brief")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isCreating || topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("New Brief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    private func createBrief() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTopic.isEmpty else {
            return
        }

        isCreating = true
        errorMessage = ""

        do {
            let brief = try await APIClient.shared.createAppointmentBrief(
                topic: trimmedTopic,
                token: token
            )

            onCreated(brief)
            dismiss()
        } catch {
            errorMessage = "Could not create appointment brief."
            print(error)
        }

        isCreating = false
    }
}

#Preview {
    NavigationStack {
        NewAppointmentBriefView(onCreated: { _ in })
            .environmentObject(AuthManager())
    }
}
