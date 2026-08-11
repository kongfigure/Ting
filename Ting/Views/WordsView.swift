import SwiftUI

// ⚠️ DEMO ONLY: hardcoded mock starred words — no real persistence yet.
private let mockWords: [Word] = [
    Word(
        id: UUID(),
        original: "蝦餃",
        romanization: "haa1 gaau2",
        meaning: "shrimp dumpling (har gow)",
        context: "Ordering dim sum",
        sourceLessonID: UUID(),
        category: "food"
    ),
    Word(
        id: UUID(),
        original: "燒賣",
        romanization: "siu1 maai2",
        meaning: "pork & shrimp dumpling (siu mai)",
        context: "Ordering dim sum",
        sourceLessonID: UUID(),
        category: "food"
    ),
    Word(
        id: UUID(),
        original: "唔該",
        romanization: "m4 goi1",
        meaning: "please / excuse me / thank you",
        context: "Everyday politeness",
        sourceLessonID: UUID(),
        category: "general"
    ),
    Word(
        id: UUID(),
        original: "電視劇",
        romanization: "din6 si6 kek6",
        meaning: "TV drama",
        context: "Discussing a TVB drama",
        sourceLessonID: UUID(),
        category: "shows"
    )
]

struct WordsView: View {
    var body: some View {
        NavigationStack {
            List(mockWords) { word in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(word.original)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(word.romanization)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    Text(word.meaning)
                        .font(.subheadline)
                    Text(word.context)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Words")
            .toolbar { TingHeader() }
        }
    }
}

#Preview {
    WordsView()
}
