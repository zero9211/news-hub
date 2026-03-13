import AVFoundation
import Speech

/// Continuously listens in the background for the configured wake word.
/// Uses single-shot SFSpeechRecognizer + auto-restart to stay compatible
/// with iOS Safari-style limitations (no true continuous mode).
final class WakeWordDetector {

    var onDetected: (() -> Void)?

    private(set) var isRunning = false
    private var wakeWord = "小艾"
    private var language = "zh-CN"

    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private let audioManager = AudioEngineManager.shared

    // MARK: – Public

    func start(wakeWord: String, language: String) {
        guard !isRunning else { return }
        self.wakeWord = wakeWord
        self.language = language
        isRunning = true
        launchSession()
    }

    func stop() {
        isRunning = false
        teardown()
        audioManager.micBufferHandler = nil
        audioManager.removeMicTap()
    }

    // MARK: – Private

    private func launchSession() {
        guard isRunning else { return }

        // If the microphone is currently being used for question recording, wait.
        guard audioManager.micBufferHandler == nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.launchSession()
            }
            return
        }

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let text = result?.bestTranscription.formattedString,
               self.textContainsWakeWord(text) {
                self.handleDetection()
                return
            }
            // Error or end of session → restart
            if error != nil || (result?.isFinal == true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.teardown()
                    self?.launchSession()
                }
            }
        }

        // Route mic audio to the recognition request
        audioManager.micBufferHandler = { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioManager.installMicTap()
    }

    private func teardown() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }

    /// Check the ASR text against the configured wake word and common
    /// homophone variants that SFSpeechRecognizer may produce instead.
    private func textContainsWakeWord(_ text: String) -> Bool {
        // Always check the exact configured word first.
        if text.contains(wakeWord) { return true }
        // "小爱" / "小艾" / "小哀" / "晓爱" are all pronounced "xiǎo ài".
        // ASR can return any of them, so we match all variants when the
        // configured word is one of them.
        let xiaoAiVariants: Set<String> = ["小爱", "小艾", "小哀", "晓爱"]
        if xiaoAiVariants.contains(wakeWord) {
            return xiaoAiVariants.contains { text.contains($0) }
        }
        return false
    }

    private func handleDetection() {
        teardown()
        audioManager.micBufferHandler = nil
        audioManager.removeMicTap()
        isRunning = false  // Caller (VoiceCallSession) will restart after the call

        DispatchQueue.main.async { [weak self] in
            self?.onDetected?()
        }
    }
}
