import AVFoundation

/// Streams GLM text response to AVSpeechSynthesizer sentence by sentence.
/// Sentences are queued as they arrive so the first words are spoken quickly.
final class VoiceResponder: NSObject, AVSpeechSynthesizerDelegate {

    var onFinished: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var queue: [String] = []
    private var pending = ""
    private var isSpeaking = false

    // Sentence terminators (Chinese + English)
    private let terminators: Set<Character> = ["。", "！", "？", "…", ".", "!", "?", "\n"]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: – Public API

    /// Feed a streaming chunk from the AI response.
    func feed(chunk: String) {
        pending += chunk
        // Flush completed sentences immediately
        while let idx = pending.firstIndex(where: { terminators.contains($0) }) {
            let sentence = String(pending[...idx]).trimmingCharacters(in: .whitespaces)
            pending = String(pending[pending.index(after: idx)...])
            if !sentence.isEmpty {
                enqueue(sentence)
            }
        }
    }

    /// Call after the stream ends to flush any remaining text.
    func flushRemaining() {
        let remainder = pending.trimmingCharacters(in: .whitespacesAndNewlines)
        pending = ""
        if !remainder.isEmpty { enqueue(remainder) }
        if queue.isEmpty && !isSpeaking {
            DispatchQueue.main.async { self.onFinished?() }
        }
    }

    /// Speak a complete message immediately (clears pending state).
    func speak(_ text: String) {
        pending = ""
        queue.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        enqueue(text)
    }

    /// Stop speaking immediately.
    func stop() {
        pending = ""
        queue.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: – Private

    private func enqueue(_ sentence: String) {
        queue.append(sentence)
        if !isSpeaking { speakNext() }
    }

    private func speakNext() {
        guard !queue.isEmpty else {
            isSpeaking = false
            DispatchQueue.main.async { self.onFinished?() }
            return
        }
        let text = queue.removeFirst()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate  = 0.52  // slightly slower than default for clarity
        utterance.pitchMultiplier = 1.05
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // MARK: – AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speakNext()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
