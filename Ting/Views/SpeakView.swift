import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let romanization: String?
}

struct SpeakView: View {
    @EnvironmentObject private var store: LessonStore
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var messages: [ChatMessage] = []
    @State private var isTranslating = false
    @State private var translationError: String?
    @State private var currentLessonID: UUID?
    @State private var pendingRetryText: String?
    @AppStorage("learningLanguage") private var learningLanguageRaw = LearningLanguage.cantonese.rawValue
    @State private var isSpeakingTarget = false
    private let apiService = ClaudeAPIService()

    private var learningLanguage: LearningLanguage {
        LearningLanguage(rawValue: learningLanguageRaw) ?? .cantonese
    }
    private var inputLocaleIdentifier: String {
        isSpeakingTarget ? learningLanguage.localeIdentifier : "en-US"
    }
    private var sourceLanguageName: String {
        isSpeakingTarget ? learningLanguage.apiName : "English"
    }
    private var targetLanguageName: String {
        isSpeakingTarget ? "English" : learningLanguage.apiName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Text("Learning")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Picker("Language", selection: $learningLanguageRaw) {
                        ForEach(LearningLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.primaryAccent)
                    .fixedSize()
                    .disabled(speechRecognizer.isRecording || isTranslating)
                    Spacer()
                }
                .padding(.horizontal)

                Picker("Speaking", selection: $isSpeakingTarget) {
                    Text("Speak English").tag(false)
                    Text("Speak \(learningLanguage.nativeName)").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(speechRecognizer.isRecording || isTranslating)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty && !speechRecognizer.isRecording {
                                ContentUnavailableView(
                                    "Tap the mic and speak",
                                    systemImage: "waveform",
                                    description: Text("Speak \(sourceLanguageName) — it gets translated to \(targetLanguageName) automatically.")
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
                                    romanization: nil
                                ))
                                .opacity(0.6)
                                .id("live")
                            }

                            if let translationError {
                                Button(action: retryTranslation) {
                                    Label(translationError, systemImage: "arrow.clockwise.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentDeep)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .disabled(pendingRetryText == nil || isTranslating)
                                .padding(.horizontal)
                                .id("error")
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
            SpeechRecognizer.logLanguageSupport()
        }
        .onChange(of: speechRecognizer.isRecording) { _, recording in
            if !recording {
                finalizeAndTranslate()
            }
        }
        .onChange(of: learningLanguageRaw) { _, _ in
            // A lesson belongs to one language, so switching starts a fresh conversation.
            isSpeakingTarget = false
            startNewConversation()
            speechRecognizer.setLocale(identifier: inputLocaleIdentifier)
        }
        .onChange(of: isSpeakingTarget) { _, _ in
            speechRecognizer.setLocale(identifier: inputLocaleIdentifier)
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            do {
                try speechRecognizer.startRecording()
            } catch {
                // Previously `try?` swallowed this — an unsupported locale or
                // AVAudioSession failure (e.g. mic permission denied) failed
                // completely silently, with no feedback that recording never started.
                translationError = error.localizedDescription
                pendingRetryText = nil
            }
        }
    }

    private func startNewConversation() {
        messages = []
        translationError = nil
        pendingRetryText = nil
        currentLessonID = nil
    }

    private func finalizeAndTranslate() {
        let spoken = speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty, !isTranslating else { return }
        speechRecognizer.transcript = ""

        messages.append(ChatMessage(isUser: true, text: spoken, romanization: nil))
        translate(spoken)
    }

    private func retryTranslation() {
        guard let spoken = pendingRetryText, !isTranslating else { return }
        translate(spoken)
    }

    /// Runs the Claude translate() call and applies its result, or — on any
    /// failure (network error, non-2xx response, malformed/empty JSON) —
    /// shows a friendly "tap to retry" message instead of leaving the
    /// "Translating…" spinner up forever or failing silently. Kept separate
    /// from finalizeAndTranslate so retrying doesn't re-append the user's
    /// message bubble.
    private func translate(_ spoken: String) {
        translationError = nil
        pendingRetryText = nil
        isTranslating = true

        Task {
            do {
                let result = try await apiService.translate(
                    text: spoken,
                    sourceLanguage: sourceLanguageName,
                    targetLanguage: targetLanguageName
                )
                messages.append(ChatMessage(
                    isUser: false,
                    text: result.translatedText,
                    romanization: result.romanization
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
                    language: learningLanguage.apiName
                )
                currentLessonID = lessonID
                store.addWords(result.notableWords, category: result.category, lessonID: lessonID)
            } catch {
                print("❌ Translate failed: \(error.localizedDescription)")
                translationError = "Translation failed — tap to retry"
                pendingRetryText = spoken
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
