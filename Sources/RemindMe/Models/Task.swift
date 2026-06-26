import Foundation

struct RTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isComplete: Bool = false
    var completedAt: Date? = nil
    var isUrgent: Bool = false
    var category: String? = nil
    var createdAt: Date = Date()

    mutating func setComplete(_ value: Bool, now: Date = Date()) {
        isComplete = value
        completedAt = value ? now : nil
    }
}

struct TaskCategory: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var sortOrder: Int = 0
}
