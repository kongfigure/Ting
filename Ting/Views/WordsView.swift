import SwiftUI

struct WordsView: View {
    @EnvironmentObject private var store: LessonStore

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading words…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.words.isEmpty {
                    ContentUnavailableView(
                        "No words yet",
                        systemImage: "star",
                        description: Text("Useful words from your conversations get collected here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.words.reversed()) { word in
                                WordCard(word: word)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Words")
            .toolbar { TingHeader() }
        }
    }
}

private struct WordCard: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(word.original)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text(word.romanization)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.primaryAccent)
                    .font(.caption)
            }
            Text(word.meaning)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            if !word.context.isEmpty {
                Text(word.context)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    WordsView()
        .environmentObject(LessonStore())
}
