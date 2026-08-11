import Foundation
import Combine

// ⚠️ SIMPLIFIED: local JSON file in Documents instead of Firebase for now.
@MainActor
final class LessonStore: ObservableObject {
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var words: [Word] = []

    private struct StoreData: Codable {
        var lessons: [Lesson]
        var words: [Word]
    }

    private let fileURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("ting_store.json")
    }()

    init() {
        load()
    }

    /// Appends a turn to the given lesson, or creates a new lesson if none exists yet.
    /// Returns the lesson ID the turn was saved to.
    func addTurn(_ turn: ConversationTurn, toLessonID lessonID: UUID?, category: String, language: String) -> UUID {
        if let lessonID, let index = lessons.firstIndex(where: { $0.id == lessonID }) {
            lessons[index].turns.append(turn)
            save()
            return lessonID
        }

        let title = String(turn.originalText.prefix(40))
        let lesson = Lesson(
            id: UUID(),
            title: title,
            category: category,
            language: language,
            turns: [turn],
            starredWordIDs: [],
            date: Date()
        )
        lessons.append(lesson)
        save()
        return lesson.id
    }

    func addWords(_ notable: [NotableWord], category: String, lessonID: UUID) {
        guard !notable.isEmpty else { return }
        for item in notable {
            guard !words.contains(where: { $0.original == item.word }) else { continue }
            let word = Word(
                id: UUID(),
                original: item.word,
                romanization: item.romanization,
                meaning: item.meaning,
                context: item.usageNote,
                sourceLessonID: lessonID,
                category: category
            )
            words.append(word)
            if let index = lessons.firstIndex(where: { $0.id == lessonID }) {
                lessons[index].starredWordIDs.append(word.id)
            }
        }
        save()
    }

    // ⚠️ SIMPLIFIED: basic day-count streak. Counts consecutive calendar days
    // with at least one lesson, ending today (or yesterday if none yet today).
    var streakDays: Int {
        let calendar = Calendar.current
        let activeDays = Set(lessons.map { calendar.startOfDay(for: $0.date) })
        guard !activeDays.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: Date())
        if !activeDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while activeDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let stored = try JSONDecoder().decode(StoreData.self, from: data)
            lessons = stored.lessons
            words = stored.words
        } catch {
            print("❌ LessonStore load failed: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(StoreData(lessons: lessons, words: words))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ LessonStore save failed: \(error)")
        }
    }
}
