import Foundation

struct AppointmentBrief: Identifiable, Codable {
    let id: Int
    let topic: String?
    let title: String?
    let content: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case topic
        case title
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AppointmentBriefsResponse: Codable {
    let appointmentBriefs: [AppointmentBrief]

    enum CodingKeys: String, CodingKey {
        case appointmentBriefs = "appointment_briefs"
    }
}

struct AppointmentBriefResponse: Codable {
    let appointmentBrief: AppointmentBrief

    enum CodingKeys: String, CodingKey {
        case appointmentBrief = "appointment_brief"
    }
}

struct CreateAppointmentBriefRequest: Codable {
    let topic: String
}
