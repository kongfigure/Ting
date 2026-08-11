import Foundation

struct ConversationTurn: Codable, Identifiable {
    let id: UUID
    let speaker: String
    let originalText: String
    let translatedText: String
    let romanization: String?
    let timestamp: Date
}

struct Lesson: Codable, Identifiable {
    let id: UUID
    var title: String
    var category: String
    let language: String
    var turns: [ConversationTurn]
    var starredWordIDs: [UUID]
    let date: Date
}

struct Word: Codable, Identifiable {
    let id: UUID
    let original: String
    let romanization: String
    let meaning: String
    let context: String
    let sourceLessonID: UUID
    let category: String
}
