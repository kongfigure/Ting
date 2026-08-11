import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let romanization: String?
    let isMock: Bool
}

// Locale verified against SFSpeechRecognizer.supportedLocales():
// zh-HK = Cantonese (Hong Kong, traditional). yue-Hant-HK is NOT supported.
enum InputLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case cantonese = "廣東話"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .cantonese: return "zh-HK"
        }
    }

    var apiName: String {
        switch self {
        case .english: return "English"
        case .cantonese: return "Cantonese"
        }
    }

    var target: InputLanguage {
        self == .english ? .cantonese : .english
    }
}

struct SpeakView: View {
    @EnvironmentObject private var store: LessonStore
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var messages: [ChatMessage] = []
    @State private var isTranslating = false
    @State private var currentLessonID: UUID?
    @State private var inputLanguage: InputLanguage = .english
    private let apiService = ClaudeAPIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Input language", selection: $inputLanguage) {
                    ForEach(InputLanguage.allCases) { language in
                        Text(language.rawValue).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 4)
                .disabled(speechRecognizer.isRecording || isTranslating)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty && !speechRecognizer.isRecording {
                                ContentUnavailableView(
                                    "Tap the mic and speak",
                                    systemImage: "waveform",
                                    description: Text("Speak \(inputLanguage.apiName) — it gets translated to \(inputLanguage.target.apiName) automatically.")
                                )
                                .padding(.top, 60)
                            }

                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if speechRecognizer.isRecording && !speechRecognizer.transcript.isEmpty {
                                ChatBubble(message: ChatMessage(
                                    isUser: true,
                                    text: speechRecognizer.transcript,
                                    romanization: nil,
                                    isMock: false
                                ))
                                .opacity(0.6)
                                .id("live")
                            }

                            if isTranslating {
                                HStack {
                                    ProgressView()
                                        .tint(Color.primaryAccent)
                                    Text("Translating…")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("translating")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: speechRecognizer.transcript) {
                        if speechRecognizer.isRecording {
                            proxy.scrollTo("live", anchor: .bottom)
                        }
                    }
                }

                Button(action: toggleRecording) {
                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 36))
                        .padding(22)
                        .background(speechRecognizer.isRecording ? Color.accentDeep : Color.primaryAccent)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }
                .padding(.bottom, 12)
                .disabled(isTranslating)
            }
            .background(Color.appBackground)
            .navigationTitle("Speak")
            .toolbar {
                TingHeader()
                ToolbarItem(placement: .topBarLeading) {
                    if !messages.isEmpty {
                        Button(action: startNewConversation) {
                            Image(systemName: "plus.bubble")
                        }
                    }
                }
            }
        }
        .task {
            await speechRecognizer.requestPermissions()
        }
        .onChange(of: speechRecognizer.isRecording) { _, recording in
            if !recording {
                finalizeAndTranslate()
            }
        }
        .onChange(of: inputLanguage) { _, language in
            speechRecognizer.setLocale(identifier: language.localeIdentifier)
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            try? speechRecognizer.startRecording()
        }
    }

    private func startNewConversation() {
        messages = []
        currentLessonID = nil
    }

    private func finalizeAndTranslate() {
        let spoken = speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty, !isTranslating else { return }
        speechRecognizer.transcript = ""

        messages.append(ChatMessage(isUser: true, text: spoken, romanization: nil, isMock: false))
        isTranslating = true

        Task {
            do {
                let result = try await apiService.translate(
                    text: spoken,
                    sourceLanguage: inputLanguage.apiName,
                    targetLanguage: inputLanguage.target.apiName
                )
                messages.append(ChatMessage(
                    isUser: false,
                    text: result.translatedText,
                    romanization: result.romanization,
                    isMock: false
                ))

                let turn = ConversationTurn(
                    id: UUID(),
                    speaker: "user",
                    originalText: spoken,
                    translatedText: result.translatedText,
                    romanization: result.romanization,
                    timestamp: Date()
                )
                let lessonID = store.addTurn(
                    turn,
                    toLessonID: currentLessonID,
                    category: result.category,
                    language: "Cantonese"
                )
                currentLessonID = lessonID
                store.addWords(result.notableWords, category: result.category, lessonID: lessonID)
            } catch {
                // ⚠️ DEMO FALLBACK: shows canned fake data if the API fails.
                // Intentionally NOT saved to the store so real lessons stay real.
                print("❌ Translate failed, using mock: \(error.localizedDescription)")
                let mock = ClaudeAPIService.mockResult(for: spoken)
                messages.append(ChatMessage(
                    isUser: false,
                    text: mock.translatedText,
                    romanization: mock.romanization,
                    isMock: true
                ))
            }
            isTranslating = false
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 48) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(message.isUser ? .body : .title3)

                if let romanization = message.romanization {
                    Text(romanization)
                        .font(.caption)
                        .foregroundStyle(message.isUser ? Color.white.opacity(0.8) : Color.textSecondary)
                }

                if message.isMock {
                    Label("demo data", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isUser ? Color.primaryAccent : Color.cardBackground)
            .foregroundColor(message.isUser ? .white : Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}

#Preview {
    SpeakView()
        .environmentObject(LessonStore())
}
