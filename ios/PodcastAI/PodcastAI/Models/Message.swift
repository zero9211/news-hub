import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    var role: String   // "system" | "user" | "assistant"
    var content: String

    init(role: String, content: String) {
        id = UUID()
        self.role = role
        self.content = content
    }

    // For GLM API serialization
    var apiDict: [String: String] {
        ["role": role, "content": content]
    }
}
