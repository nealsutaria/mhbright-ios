import SwiftUI

struct EditRecordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let record: HealthRecord
    let onRecordUpdated: (HealthRecord) -> Void

    @State private var date: Date
    @State private var reason: String
    @State private var prescription: Bool
    @State private var prescriptionName: String
    @State private var xrayDone: Bool
    @State private var testDone: Bool
    @State private var testType: String
    @State private var doctorRating: Int
    @State private var comments: String

    @State private var isSaving = false
    @State private var errorMessage = ""

    init(record: HealthRecord, onRecordUpdated: @escaping (HealthRecord) -> Void) {
        self.record = record
        self.onRecordUpdated = onRecordUpdated

        _date = State(initialValue: Self.parseDate(record.date) ?? Date())
        _reason = State(initialValue: record.reason ?? "")
        _prescription = State(initialValue: record.prescription ?? false)
        _prescriptionName = State(initialValue: record.prescriptionName ?? "")
        _xrayDone = State(initialValue: record.xrayDone ?? false)
        _testDone = State(initialValue: record.testDone ?? false)
        _testType = State(initialValue: record.testType ?? "")
        _doctorRating = State(initialValue: record.doctorRating ?? 3)
        _comments = State(initialValue: record.comments ?? "")
    }

    var body: some View {
        Form {
            Section("Visit Info") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Reason for visit", text: $reason)
            }

            Section("Prescription") {
                Toggle("Prescription?", isOn: $prescription)

                if prescription {
                    TextField("Prescription name", text: $prescriptionName)
                }
            }

            Section("Tests") {
                Toggle("X-ray done?", isOn: $xrayDone)
                Toggle("Test done?", isOn: $testDone)

                if testDone {
                    TextField("Test type", text: $testType)
                }
            }

            Section("Doctor Rating") {
                Picker("Rating", selection: $doctorRating) {
                    ForEach(1...5, id: \.self) { rating in
                        Text("\(rating)").tag(rating)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Comments") {
                TextEditor(text: $comments)
                    .frame(minHeight: 120)
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
                        await saveChanges()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSaving || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Edit Record")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isSaving = true
        errorMessage = ""

        do {
            let updatedRecord = try await APIClient.shared.updateRecord(
                id: record.id,
                token: token,
                date: Self.formattedDate(date),
                reason: reason,
                prescription: prescription,
                prescriptionName: prescriptionName,
                xrayDone: xrayDone,
                testDone: testDone,
                testType: testType,
                doctorRating: doctorRating,
                comments: comments
            )

            onRecordUpdated(updatedRecord)
            dismiss()
        } catch {
            errorMessage = "Could not update record."
            print(error)
        }

        isSaving = false
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

#Preview {
    NavigationStack {
        EditRecordView(
            record: HealthRecord(
                id: 1,
                date: "2026-07-18",
                reason: "Checkup",
                prescription: false,
                prescriptionName: "",
                xrayDone: false,
                testDone: false,
                testType: "",
                doctorRating: 4,
                comments: "Preview comments",
                imageUrl: nil,
                createdAt: nil,
                updatedAt: nil,
                analysis: nil
            ),
            onRecordUpdated: { _ in }
        )
        .environmentObject(AuthManager())
    }
}
