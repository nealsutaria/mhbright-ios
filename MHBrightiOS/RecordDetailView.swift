import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject var authManager: AuthManager

    let recordId: Int

    @State private var record: HealthRecord?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isAnalyzing = false
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    @State private var showEditSheet = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView("Loading record...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if let record {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(record.reason ?? "Untitled record")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(record.date ?? "No date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    DetailCard(title: "Comments") {
                        Text(nonEmpty(record.comments) ?? "No comments added.")
                            .foregroundStyle(.secondary)
                    }

                    DetailCard(title: "Visit Details") {
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(label: "Prescription", value: yesNo(record.prescription))
                            DetailRow(label: "Prescription Name", value: nonEmpty(record.prescriptionName) ?? "None")
                            DetailRow(label: "X-ray Done", value: yesNo(record.xrayDone))
                            DetailRow(label: "Test Done", value: yesNo(record.testDone))
                            DetailRow(label: "Test Type", value: nonEmpty(record.testType) ?? "None")

                            if let rating = record.doctorRating {
                                DetailRow(label: "Doctor Rating", value: "\(rating)/5")
                            } else {
                                DetailRow(label: "Doctor Rating", value: "Not rated")
                            }
                        }
                    }

                    if let imageUrl = record.imageUrl, let url = URL(string: imageUrl) {
                        DetailCard(title: "Uploaded Image") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                case .failure:
                                    Text("Could not load image.")
                                        .foregroundStyle(.secondary)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }

                    DetailCard(title: "AI Analysis") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(nonEmpty(record.analysis) ?? "No analysis yet.")
                                .foregroundStyle(.secondary)

                            if record.imageUrl != nil {
                                Button {
                                    Task {
                                        await analyzeImage()
                                    }
                                } label: {
                                    if isAnalyzing {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        Text("Analyze Image")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                .background(Color.indigo)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .disabled(isAnalyzing)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(record == nil)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(isDeleting)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let record {
                NavigationStack {
                    EditRecordView(record: record) { updatedRecord in
                        self.record = updatedRecord
                    }
                    .environmentObject(authManager)
                }
            }
        }
        .alert("Delete Record?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteRecord()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This record will be permanently deleted.")
        }
        .task {
            await loadRecord()
        }
    }

    private func loadRecord() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            record = try await APIClient.shared.fetchRecord(id: recordId, token: token)
        } catch {
            errorMessage = "Could not load record."
            print(error)
        }

        isLoading = false
    }
    
    private func analyzeImage() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        guard let record else {
            errorMessage = "Missing record."
            return
        }

        isAnalyzing = true
        errorMessage = ""

        do {
            self.record = try await APIClient.shared.analyzeRecordImage(id: record.id, token: token)
        } catch {
            errorMessage = "Could not analyze image."
            print(error)
        }

        isAnalyzing = false
    }

    private func yesNo(_ value: Bool?) -> String {
        if value == true { return "Yes" }
        if value == false { return "No" }
        return "Not specified"
    }

    private func nonEmpty(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return text
    }
    
    private func deleteRecord() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isDeleting = true
        errorMessage = ""

        do {
            try await APIClient.shared.deleteRecord(id: recordId, token: token)
            dismiss()
        } catch {
            errorMessage = "Could not delete record."
            print(error)
        }

        isDeleting = false
    }
}



struct DetailCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        RecordDetailView(recordId: 1)
            .environmentObject(AuthManager())
    }
}
