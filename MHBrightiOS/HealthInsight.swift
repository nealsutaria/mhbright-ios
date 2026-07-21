import Foundation

struct HealthInsight: Identifiable, Codable {
    let id: Int
    let recordId: Int?
    let title: String?
    let body: String?
    let severity: String?
    let status: String?
    let source: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case title
        case body
        case severity
        case status
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HealthInsightsResponse: Codable {
    let healthInsights: [HealthInsight]

    enum CodingKeys: String, CodingKey {
        case healthInsights = "health_insights"
    }
}
