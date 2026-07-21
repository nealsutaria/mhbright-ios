import SwiftUI

struct HealthInsightsView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var insights: [HealthInsight] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading insights...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if insights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.largeTitle)

                    Text("No insights yet")
                        .font(.headline)

                    Text("Insights appear after MHBright analyzes patterns across your saved health records.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(insights) { insight in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(insight.title ?? "Health Insight")
                                    .font(.headline)

                                Spacer()

                                Text((insight.severity ?? "unknown").capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(severityBackground(insight.severity))
                                    .clipShape(Capsule())
                            }

                            Text(insight.body ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let source = insight.source, !source.isEmpty {
                                Text("Source: \(source)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Health Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInsights()
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

    private func loadInsights() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            insights = try await APIClient.shared.fetchHealthInsights(token: token)
        } catch {
            errorMessage = "Could not load health insights."
            print(error)
        }

        isLoading = false
    }

    private func severityBackground(_ severity: String?) -> Color {
        switch severity {
        case "high":
            return Color.red.opacity(0.15)
        case "medium":
            return Color.orange.opacity(0.15)
        case "low":
            return Color.green.opacity(0.15)
        default:
            return Color.gray.opacity(0.15)
        }
    }
}

#Preview {
    NavigationStack {
        HealthInsightsView()
            .environmentObject(AuthManager())
    }
}
