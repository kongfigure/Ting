import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init(localeIdentifier: String = "en-US") {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    func setLocale(identifier: String) {
        guard !isRecording else { return }
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        if recognizer == nil {
            print("❌ SFSpeechRecognizer unavailable for locale \(identifier)")
        }
    }

    static func logLanguageSupport() {
        let supported = SFSpeechRecognizer.supportedLocales().map(\.identifier).sorted()
        print("🎙️ SFSpeechRecognizer supports \(supported.count) locales:")
        print("   \(supported.joined(separator: ", "))")
        print("🎙️ Curated language availability:")
        for language in LearningLanguage.allCases {
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeIdentifier))
            let available = recognizer?.isAvailable ?? false
            let onDevice = recognizer?.supportsOnDeviceRecognition ?? false
            print("   \(language.apiName) [\(language.localeIdentifier)] available=\(available) onDevice=\(onDevice)")
        }
    }

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        let micStatus = await AVAudioApplication.requestRecordPermission()
        print("Speech: \(speechStatus.rawValue), Mic: \(micStatus)")
    }

    func startRecording() throws {
        task?.cancel()
        task = nil
        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            Task { @MainActor in
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.request = nil
                    self.task = nil
                    self.isRecording = false
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        isRecording = false
    }
}
