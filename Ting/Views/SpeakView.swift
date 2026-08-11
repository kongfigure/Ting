import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let romanization: String?
    let isMock: Bool
}

struct SpeakView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var messages: [ChatMessage] = []
    @State private var isTranslating = false
    private let apiService = ClaudeAPIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty && !speechRecognizer.isRecording {
                                ContentUnavailableView(
                                    "Tap the mic and speak",
                                    systemImage: "waveform",
                                    description: Text("Your words get translated to Cantonese automatically.")
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
                                    Text("Translating…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
                        .background(speechRecognizer.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.bottom, 12)
                .disabled(isTranslating)
            }
            .navigationTitle("Speak")
            .toolbar { TingHeader() }
        }
        .task {
            await speechRecognizer.requestPermissions()
        }
        .onChange(of: speechRecognizer.isRecording) { _, recording in
            if !recording {
                finalizeAndTranslate()
            }
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            try? speechRecognizer.startRecording()
        }
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
                    sourceLanguage: "English",
                    targetLanguage: "Cantonese"
                )
                messages.append(ChatMessage(
                    isUser: false,
                    text: result.translatedText,
                    romanization: result.romanization,
                    isMock: false
                ))
            } catch {
                // ⚠️ DEMO FALLBACK: shows canned fake data if the API fails
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
                        .foregroundStyle(message.isUser ? .white.opacity(0.8) : .secondary)
                }

                if message.isMock {
                    Label("demo data", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isUser ? Color.blue : Color(.systemGray5))
            .foregroundColor(message.isUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}

#Preview {
    SpeakView()
}
