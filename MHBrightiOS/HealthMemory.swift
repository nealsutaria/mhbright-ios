import Foundation

struct HealthMemory: Identifiable, Codable {
    let id: Int
    let recordId: Int?
    let category: String?
    let title: String?
    let value: String?
    let sourceDate: String?
    let confidence: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case category
        case title
        case value
        case sourceDate = "source_date"
        case confidence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HealthMemoriesResponse: Codable {
    let healthMemories: [HealthMemory]

    enum CodingKeys: String, CodingKey {
        case healthMemories = "health_memories"
    }
}
