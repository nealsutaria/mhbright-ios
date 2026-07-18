import SwiftUI
import PhotosUI

struct NewRecordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var reason = ""
    @State private var prescription = false
    @State private var prescriptionName = ""
    @State private var xrayDone = false
    @State private var testDone = false
    @State private var testType = ""
    @State private var doctorRating = 3
    @State private var comments = ""

    @State private var isSaving = false
    @State private var errorMessage = ""
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: Image?

    let onRecordCreated: () -> Void

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
            
            Section("Image") {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo")
                        Text(selectedImageData == nil ? "Choose Image" : "Change Image")
                    }
                }

                if let selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data

                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await saveRecord()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Record")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSaving || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("New Record")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveRecord() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isSaving = true
        errorMessage = ""

        do {
            _ = try await APIClient.shared.createRecordWithImage(
                token: token,
                date: formattedDate(date),
                reason: reason,
                prescription: prescription,
                prescriptionName: prescriptionName,
                xrayDone: xrayDone,
                testDone: testDone,
                testType: testType,
                doctorRating: doctorRating,
                comments: comments,
                imageData: selectedImageData
            )

            onRecordCreated()
            dismiss()
        } catch {
            errorMessage = "Could not save record."
            print(error)
        }

        isSaving = false
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        NewRecordView(onRecordCreated: {})
            .environmentObject(AuthManager())
    }
}
