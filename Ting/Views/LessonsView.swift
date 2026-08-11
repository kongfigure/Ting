import SwiftUI

// ⚠️ DEMO ONLY: hardcoded mock lessons — no real persistence yet.
private let mockLessons: [Lesson] = [
    Lesson(
        id: UUID(),
        title: "Ordering dim sum",
        category: "food",
        language: "Cantonese",
        turns: [],
        starredWordIDs: [],
        date: Date().addingTimeInterval(-86400)
    ),
    Lesson(
        id: UUID(),
        title: "Talking about my week",
        category: "general",
        language: "Cantonese",
        turns: [],
        starredWordIDs: [],
        date: Date().addingTimeInterval(-3 * 86400)
    ),
    Lesson(
        id: UUID(),
        title: "Discussing a TVB drama",
        category: "shows",
        language: "Cantonese",
        turns: [],
        starredWordIDs: [],
        date: Date().addingTimeInterval(-6 * 86400)
    )
]

struct LessonsView: View {
    var body: some View {
        NavigationStack {
            List(mockLessons) { lesson in
                VStack(alignment: .leading, spacing: 6) {
                    Text(lesson.title)
                        .font(.headline)
                    HStack {
                        Text(lesson.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor(lesson.category).opacity(0.2))
                            .foregroundStyle(categoryColor(lesson.category))
                            .clipShape(Capsule())
                        Spacer()
                        Text(lesson.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Lessons")
            .toolbar { TingHeader() }
        }
    }
}

func categoryColor(_ category: String) -> Color {
    switch category {
    case "food": return .orange
    case "work": return .blue
    case "shows": return .purple
    case "school": return .green
    default: return .gray
    }
}

#Preview {
    LessonsView()
}
