import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: LessonStore

    // ⚠️ SIMPLIFIED: progress = phrases spoken / 30, capped at 100%.
    // A real fluency metric would need vocabulary coverage, review accuracy, etc.
    private var languageStats: [(name: String, phrases: Int, progress: Double)] {
        Dictionary(grouping: store.lessons, by: \.language)
            .map { language, lessons in
                let phrases = lessons.reduce(0) { $0 + $1.turns.count }
                return (language, phrases, min(Double(phrases) / 30.0, 1.0))
            }
            .sorted { $0.phrases > $1.phrases }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(store.streakDays)",
                            label: "day streak",
                            systemImage: "flame.fill"
                        )
                        StatCard(
                            value: "\(store.lessons.count)",
                            label: "conversations",
                            systemImage: "bubble.left.and.bubble.right.fill"
                        )
                        StatCard(
                            value: "\(store.words.count)",
                            label: "words saved",
                            systemImage: "star.fill"
                        )
                    }

                    if languageStats.isEmpty {
                        ContentUnavailableView(
                            "No progress yet",
                            systemImage: "chart.bar",
                            description: Text("Start speaking and your progress will show up here.")
                        )
                        .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Language progress")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)

                            ForEach(languageStats, id: \.name) { stat in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(stat.name)
                                            .font(.headline)
                                            .foregroundStyle(Color.textPrimary)
                                        Spacer()
                                        Text(levelLabel(stat.progress))
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    ProgressView(value: stat.progress)
                                        .tint(Color.primaryAccent)
                                    Text("\(stat.phrases) phrase\(stat.phrases == 1 ? "" : "s") spoken")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .cardStyle()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Stats")
            .toolbar { TingHeader() }
        }
    }

    private func levelLabel(_ progress: Double) -> String {
        switch progress {
        case ..<0.25: return "Just started"
        case ..<0.5: return "Beginner"
        case ..<0.75: return "Getting there"
        default: return "Conversational"
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.primaryAccent)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    StatsView()
        .environmentObject(LessonStore())
}
