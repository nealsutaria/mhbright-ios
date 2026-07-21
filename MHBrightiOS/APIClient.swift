import Foundation

struct LoginResponse: Codable {
    let token: String
    let user: APIUser
}

struct APIUser: Codable {
    let id: Int
    let email: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}


struct CreateRecordRequest: Codable {
    let record: CreateRecordBody
}

struct CreateRecordBody: Codable {
    let date: String
    let reason: String
    let prescription: Bool
    let prescriptionName: String
    let xrayDone: Bool
    let testDone: Bool
    let testType: String
    let doctorRating: Int?
    let comments: String

    enum CodingKeys: String, CodingKey {
        case date
        case reason
        case prescription
        case prescriptionName = "prescription_name"
        case xrayDone = "xray_done"
        case testDone = "test_done"
        case testType = "test_type"
        case doctorRating = "doctor_rating"
        case comments
    }
}


class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://127.0.0.1:3000")!

    private init() {}

    func login(email: String, password: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("/api/v1/login")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func fetchRecords(token: String) async throws -> [HealthRecord] {
        let url = baseURL.appendingPathComponent("/api/v1/records")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode([HealthRecord].self, from: data)
    }
    
    func fetchRecord(id: Int, token: String) async throws -> HealthRecord {
        let url = baseURL.appendingPathComponent("/api/v1/records/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(HealthRecord.self, from: data)
    }
    
    func analyzeRecordImage(id: Int, token: String) async throws -> HealthRecord {
        let url = baseURL.appendingPathComponent("/api/v1/records/\(id)/analyze_image")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(HealthRecord.self, from: data)
    }
    
    func createRecord(
        token: String,
        date: String,
        reason: String,
        prescription: Bool,
        prescriptionName: String,
        xrayDone: Bool,
        testDone: Bool,
        testType: String,
        doctorRating: Int?,
        comments: String
    ) async throws -> HealthRecord {
        let url = baseURL.appendingPathComponent("/api/v1/records")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = CreateRecordRequest(
            record: CreateRecordBody(
                date: date,
                reason: reason,
                prescription: prescription,
                prescriptionName: prescriptionName,
                xrayDone: xrayDone,
                testDone: testDone,
                testType: testType,
                doctorRating: doctorRating,
                comments: comments
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(HealthRecord.self, from: data)
    }
    
    func createRecordWithImage(
        token: String,
        date: String,
        reason: String,
        prescription: Bool,
        prescriptionName: String,
        xrayDone: Bool,
        testDone: Bool,
        testType: String,
        doctorRating: Int?,
        comments: String,
        imageData: Data?
    ) async throws -> HealthRecord {
        let url = baseURL.appendingPathComponent("/api/v1/records")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"record[\(name)]\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField(name: "date", value: date)
        appendField(name: "reason", value: reason)
        appendField(name: "prescription", value: prescription ? "true" : "false")
        appendField(name: "prescription_name", value: prescriptionName)
        appendField(name: "xray_done", value: xrayDone ? "true" : "false")
        appendField(name: "test_done", value: testDone ? "true" : "false")
        appendField(name: "test_type", value: testType)

        if let doctorRating {
            appendField(name: "doctor_rating", value: "\(doctorRating)")
        }

        appendField(name: "comments", value: comments)

        if let imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"record[image]\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(HealthRecord.self, from: data)
    }
    
    func deleteRecord(id: Int, token: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/records/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }
    
    func updateRecord(
        id: Int,
        token: String,
        date: String,
        reason: String,
        prescription: Bool,
        prescriptionName: String,
        xrayDone: Bool,
        testDone: Bool,
        testType: String,
        doctorRating: Int?,
        comments: String
    ) async throws -> HealthRecord {
        let url = baseURL.appendingPathComponent("/api/v1/records/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = CreateRecordRequest(
            record: CreateRecordBody(
                date: date,
                reason: reason,
                prescription: prescription,
                prescriptionName: prescriptionName,
                xrayDone: xrayDone,
                testDone: testDone,
                testType: testType,
                doctorRating: doctorRating,
                comments: comments
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(HealthRecord.self, from: data)
    }
    
    func logout(token: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/logout")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }
    
    func fetchChatMessages(token: String) async throws -> [ChatMessage] {
        let url = baseURL.appendingPathComponent("/api/v1/chat/messages")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChatMessagesResponse.self, from: data)
        return decoded.messages
    }

    func sendChatMessage(message: String, token: String) async throws -> [ChatMessage] {
        let url = baseURL.appendingPathComponent("/api/v1/chat/messages")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = SendChatMessageRequest(message: message)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(SendChatMessageResponse.self, from: data)
        return decoded.messages
    }

    func clearChatMessages(token: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/chat/messages")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }
    
    func fetchAppointmentBriefs(token: String) async throws -> [AppointmentBrief] {
        let url = baseURL.appendingPathComponent("/api/v1/appointment_briefs")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AppointmentBriefsResponse.self, from: data)
        return decoded.appointmentBriefs
    }

    func fetchAppointmentBrief(id: Int, token: String) async throws -> AppointmentBrief {
        let url = baseURL.appendingPathComponent("/api/v1/appointment_briefs/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AppointmentBriefResponse.self, from: data)
        return decoded.appointmentBrief
    }

    func createAppointmentBrief(topic: String, token: String) async throws -> AppointmentBrief {
        let url = baseURL.appendingPathComponent("/api/v1/appointment_briefs")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = CreateAppointmentBriefRequest(topic: topic)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AppointmentBriefResponse.self, from: data)
        return decoded.appointmentBrief
    }

    func regenerateAppointmentBrief(id: Int, token: String) async throws -> AppointmentBrief {
        let url = baseURL.appendingPathComponent("/api/v1/appointment_briefs/\(id)/regenerate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AppointmentBriefResponse.self, from: data)
        return decoded.appointmentBrief
    }

    func deleteAppointmentBrief(id: Int, token: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/appointment_briefs/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }
    
    func fetchHealthInsights(token: String) async throws -> [HealthInsight] {
        let url = baseURL.appendingPathComponent("/api/v1/health_insights")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(HealthInsightsResponse.self, from: data)
        return decoded.healthInsights
    }
    
    func signup(email: String, password: String, passwordConfirmation: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("/api/v1/signup")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: [String: String]] = [
            "user": [
                "email": email,
                "password": password,
                "password_confirmation": passwordConfirmation
            ]
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case badStatusCode(Int)
}
