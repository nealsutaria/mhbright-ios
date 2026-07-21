import SwiftUI

struct HealthMemoriesView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var memories: [HealthMemory] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading memories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if memories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.largeTitle)

                    Text("No health memories yet")
                        .font(.headline)

                    Text("Memories are facts MHBright extracts from your saved records.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(memories) { memory in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(memory.title ?? "Health Memory")
                                    .font(.headline)

                                Spacer()

                                if let category = memory.category, !category.isEmpty {
                                    Text(category.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            Text(memory.value ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                if let sourceDate = memory.sourceDate {
                                    Text("Date: \(sourceDate)")
                                }

                                if let confidence = memory.confidence {
                                    Text("Confidence: \(confidence)%")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Health Memories")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMemories()
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

    private func loadMemories() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            memories = try await APIClient.shared.fetchHealthMemories(token: token)
        } catch {
            errorMessage = "Could not load health memories."
            print(error)
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        HealthMemoriesView()
            .environmentObject(AuthManager())
    }
}
