import SwiftUI

// ⚠️ DEMO ONLY: hardcoded mock stats — nothing is actually tracked yet.
private struct LanguageProgress: Identifiable {
    let id = UUID()
    let name: String
    let flag: String
    let progress: Double
    let level: String
}

private let mockLanguages: [LanguageProgress] = [
    LanguageProgress(name: "Cantonese", flag: "🇭🇰", progress: 0.62, level: "Conversational"),
    LanguageProgress(name: "Spanish", flag: "🇪🇸", progress: 0.34, level: "Beginner"),
    LanguageProgress(name: "Mandarin", flag: "🇹🇼", progress: 0.15, level: "Just started")
]

struct StatsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        StatCard(
                            value: "12",
                            label: "day streak",
                            systemImage: "flame.fill",
                            color: .orange
                        )
                        StatCard(
                            value: "27",
                            label: "conversations",
                            systemImage: "bubble.left.and.bubble.right.fill",
                            color: .blue
                        )
                        StatCard(
                            value: "48",
                            label: "words starred",
                            systemImage: "star.fill",
                            color: .yellow
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Language progress") {
                    ForEach(mockLanguages) { language in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(language.flag) \(language.name)")
                                    .font(.headline)
                                Spacer()
                                Text(language.level)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: language.progress)
                                .tint(progressColor(language.progress))
                            Text("\(Int(language.progress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Stats")
            .toolbar { TingHeader() }
        }
    }

    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case ..<0.25: return .red
        case ..<0.5: return .orange
        default: return .green
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    StatsView()
}
