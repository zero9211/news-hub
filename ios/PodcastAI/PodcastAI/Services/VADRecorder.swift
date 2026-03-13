import AVFoundation
import Speech

/// Records user speech using AVAudioEngine + SFSpeechRecognizer.
/// Uses RMS energy to detect end of speech (VAD = Voice Activity Detection).
final class VADRecorder {

    // ── Callbacks ──────────────────────────────────────────────────
    var onTranscriptUpdate: ((String) -> Void)?
    var onSpeechEnd: ((String) -> Void)?
    var onInterrupt: (() -> Void)?   // called when user speaks during AI response

    // ── State ──────────────────────────────────────────────────────
    private(set) var isRecording = false
    /// When true, VAD watches for speech start to signal an interrupt
    var monitorForInterrupt = false

    // ── VAD tuning ─────────────────────────────────────────────────
    private let activationThreshold: Float = 0.015  // RMS to start tracking
    private let interruptThreshold:  Float = 0.025  // RMS to trigger interrupt
    private let silenceDuration:   TimeInterval = 1.2  // seconds of silence → end

    // ── Internals ──────────────────────────────────────────────────
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var silenceTimer: Timer?
    private var latestTranscript = ""

    private let audioManager = AudioEngineManager.shared

    // MARK: – Public API

    func startRecording(language: String) {
        guard !isRecording else { return }
        isRecording = true
        latestTranscript = ""
        monitorForInterrupt = false

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            let text = result.bestTranscription.formattedString
            self.latestTranscript = text
            DispatchQueue.main.async { self.onTranscriptUpdate?(text) }
        }

        // Route mic audio → recognition + VAD
        audioManager.micBufferHandler = { [weak self] buffer, _ in
            guard let self else { return }
            self.recognitionRequest?.append(buffer)
            self.processVAD(buffer: buffer)
        }
        audioManager.installMicTap()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        monitorForInterrupt = false
        silenceTimer?.invalidate()
        silenceTimer = nil

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        audioManager.micBufferHandler = nil
        audioManager.removeMicTap()

        let transcript = latestTranscript
        latestTranscript = ""
        DispatchQueue.main.async { [weak self] in
            self?.onSpeechEnd?(transcript)
        }
    }

    // MARK: – VAD

    private func processVAD(buffer: AVAudioPCMBuffer) {
        let rms = computeRMS(buffer: buffer)

        if monitorForInterrupt {
            if rms > interruptThreshold {
                DispatchQueue.main.async { [weak self] in
                    self?.onInterrupt?()
                }
            }
            return
        }

        // Normal recording VAD: reset silence timer when speech detected
        if rms > activationThreshold {
            silenceTimer?.invalidate()
            silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
                self?.stopRecording()
            }
        }
    }

    private func computeRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        return sqrt(sum / Float(count))
    }
}
