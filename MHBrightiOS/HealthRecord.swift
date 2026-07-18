import Foundation

struct HealthRecord: Codable, Identifiable {
    let id: Int
    let date: String?
    let reason: String?
    let prescription: Bool?
    let prescriptionName: String?
    let xrayDone: Bool?
    let testDone: Bool?
    let testType: String?
    let doctorRating: Int?
    let comments: String?
    let imageUrl: String?
    let createdAt: String?
    let updatedAt: String?
    let analysis: String?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case reason
        case prescription
        case prescriptionName = "prescription_name"
        case xrayDone = "xray_done"
        case testDone = "test_done"
        case testType = "test_type"
        case doctorRating = "doctor_rating"
        case comments
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case analysis
    }
}
