import SwiftUI

struct LessonsView: View {
    @EnvironmentObject private var store: LessonStore

    var body: some View {
        NavigationStack {
            Group {
                if store.lessons.isEmpty {
                    ContentUnavailableView(
                        "No lessons yet",
                        systemImage: "book",
                        description: Text("Have a conversation on the Speak tab and it will be saved here automatically.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.lessons.sorted { $0.date > $1.date }) { lesson in
                                LessonCard(lesson: lesson)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Lessons")
            .toolbar { TingHeader() }
        }
    }
}

private struct LessonCard: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            HStack {
                Text(lesson.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryAccent.opacity(0.15))
                    .foregroundStyle(Color.accentDeep)
                    .clipShape(Capsule())
                Text("\(lesson.turns.count) phrase\(lesson.turns.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text(lesson.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    LessonsView()
        .environmentObject(LessonStore())
}
