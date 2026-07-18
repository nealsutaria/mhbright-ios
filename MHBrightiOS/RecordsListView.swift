import SwiftUI

struct RecordsListView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var records: [HealthRecord] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading records...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(records) { record in
                NavigationLink {
                    RecordDetailView(recordId: record.id)
                        .environmentObject(authManager)
                } label: {
                    recordCard(record)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    NewRecordView {
                        Task {
                            await loadRecords()
                        }
                    }
                    .environmentObject(authManager)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadRecords()
        }
    }

    private func recordCard(_ record: HealthRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(record.reason ?? "Untitled record")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(record.date ?? "No date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let comments = record.comments, !comments.isEmpty {
                Text(comments)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if record.imageUrl != nil {
                    Label("Image", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }

                if record.analysis != nil {
                    Label("Analyzed", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }

                if let rating = record.doctorRating {
                    Label("\(rating)/5", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.vertical, 6)
    }

    private func loadRecords() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            records = try await APIClient.shared.fetchRecords(token: token)
        } catch {
            errorMessage = "Could not load records."
            print(error)
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        RecordsListView()
            .environmentObject(AuthManager())
    }
}
