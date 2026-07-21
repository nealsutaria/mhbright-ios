import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: Int
    let role: String
    let content: String
    let createdAt: String?
    let updatedAt: String?

    var isUser: Bool {
        role == "user"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ChatMessagesResponse: Codable {
    let messages: [ChatMessage]
}

struct SendChatMessageRequest: Codable {
    let message: String
}

struct SendChatMessageResponse: Codable {
    let response: String
    let messages: [ChatMessage]
}
