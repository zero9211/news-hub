import AVFoundation
import Observation

/// Core state machine for the "phone call" voice conversation session.
/// Orchestrates: WakeWordDetector → VADRecorder → GLMService → VoiceResponder
@Observable
final class VoiceCallSession {

    // ── Phase ──────────────────────────────────────────────────────
    enum Phase: Equatable {
        case idle
        case listening
        case processing
        case speaking
    }

    var phase: Phase = .idle
    var liveTranscript = ""     // real-time user speech
    var aiTranscript   = ""     // AI response text being spoken
    var callDuration: TimeInterval = 0
    var errorMessage: String?

    // ── Services ───────────────────────────────────────────────────
    private let glm:          GLMService
    private let tts:          VoiceResponder
    private let vad:          VADRecorder
    let wakeDetector:         WakeWordDetector
    let player:               PodcastPlayer

    // ── Conversation state ──────────────────────────────────────────
    private var messages: [Message] = []
    private var callTimer: Timer?

    // ── Config (injected from AppState) ────────────────────────────
    var userLang    = "zh-CN"
    var podcastLang = "en-US"

    // MARK: – Init

    init(glm: GLMService, tts: VoiceResponder, vad: VADRecorder,
         wakeDetector: WakeWordDetector, player: PodcastPlayer) {
        self.glm          = glm
        self.tts          = tts
        self.vad          = vad
        self.wakeDetector = wakeDetector
        self.player       = player

        wired()
    }

    private func wired() {
        vad.onTranscriptUpdate = { [weak self] text in
            self?.liveTranscript = text
        }
        vad.onSpeechEnd = { [weak self] transcript in
            self?.handleUserFinishedSpeaking(transcript)
        }
        vad.onInterrupt = { [weak self] in
            self?.handleInterrupt()
        }
        tts.onFinished = { [weak self] in
            self?.handleAIFinishedSpeaking()
        }
        wakeDetector.onDetected = { [weak self] in
            self?.startCall()
        }
    }

    // MARK: – Call lifecycle

    func startCall() {
        guard phase == .idle else { return }

        player.pause()

        // Build system prompt (initial; updated with podcast context per turn)
        messages = [buildSystemMessage()]

        phase         = .listening
        liveTranscript = ""
        aiTranscript  = ""
        callDuration  = 0

        startCallTimer()

        vad.startRecording(language: userLang)
    }

    func endCall(sayFarewell: Bool = false) {
        vad.stopRecording()
        tts.stop()
        callTimer?.invalidate()
        callTimer = nil
        phase = .idle

        if sayFarewell {
            let bye = tts  // capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                bye.speak("好的，继续享受播客！")
                bye.onFinished = { [weak self] in
                    self?.player.play()
                    // Restart wake detection
                    self?.restartWakeDetector()
                }
            }
        } else {
            player.play()
            restartWakeDetector()
        }
    }

    // MARK: – Speech handling

    private func handleUserFinishedSpeaking(_ transcript: String) {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty utterance → stay listening
        guard !text.isEmpty else {
            vad.startRecording(language: userLang)
            return
        }

        // Exit intent?
        if isExitPhrase(text) {
            endCall(sayFarewell: true)
            return
        }

        phase = .processing
        liveTranscript = text
        messages.append(Message(role: "user", content: text))

        Task { await sendToAI() }
    }

    private func handleInterrupt() {
        tts.stop()
        aiTranscript = ""
        vad.monitorForInterrupt = false
        phase = .listening
        vad.startRecording(language: userLang)
    }

    private func handleAIFinishedSpeaking() {
        vad.monitorForInterrupt = false
        aiTranscript   = ""
        liveTranscript = ""
        // Auto-end after one Q&A round; ContentView.onChange restarts wake detection.
        endCall(sayFarewell: false)
    }

    // MARK: – AI call

    private func sendToAI() async {
        // Optionally enrich system prompt with podcast audio context
        await updateSystemMessageWithContext()

        phase = .speaking
        aiTranscript = ""
        var fullResponse = ""

        let stream = glm.streamChat(messages: messages)
        vad.monitorForInterrupt = true

        do {
            for try await chunk in stream {
                fullResponse += chunk
                await MainActor.run {
                    self.aiTranscript += chunk
                    self.tts.feed(chunk: chunk)
                }
            }
            tts.flushRemaining()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.tts.speak("抱歉，网络出现问题，请稍后再试。")
            }
        }

        if !fullResponse.isEmpty {
            messages.append(Message(role: "assistant", content: fullResponse))
        }
    }

    // MARK: – System prompt

    private func buildSystemMessage() -> Message {
        let info = "播客：\(player.title)  播放位置：\(player.positionString)"
        let content = """
        你是专业的AI播客伴侣，正通过语音陪用户收听播客。

        \(info)

        你的能力：
        1. 单词讲解：词义、音标、例句、连读弱读规则
        2. 句子分析：翻译、语法、语气
        3. 口音识别：美式/英式/澳式/印度英语特点分析
        4. 背景知识：人物、地名、文化典故、历史事件

        语音对话规则（非常重要）：
        - 这是语音对话，回答必须口语化，不要使用Markdown格式
        - 不要使用星号、井号、代码块等符号，直接说话
        - 每次回答控制在3~5句话，简洁有力
        - 语言：中文为主，英语单词直接说出发音
        - 若用户说"结束"、"再见"等，友好道别
        """
        return Message(role: "system", content: content)
    }

    private func updateSystemMessageWithContext() async {
        guard !messages.isEmpty else { return }

        // Try to get recent podcast audio context via ASR
        if let audioData = player.getRecentAmbientData(seconds: 30),
           !glm.apiKey.isEmpty {
            let transcript = (try? await glm.transcribe(audioData: audioData, language: podcastLang)) ?? ""
            if !transcript.isEmpty {
                var updated = buildSystemMessage()
                updated = Message(role: "system",
                                  content: updated.content + "\n\n当前正在播放（最近30秒）：\"\(transcript)\"")
                messages[0] = updated
                return
            }
        }

        // Fallback: update position only
        messages[0] = buildSystemMessage()
    }

    // MARK: – Helpers

    private func isExitPhrase(_ text: String) -> Bool {
        let exits = ["结束", "再见", "谢谢了", "拜拜", "不聊了", "bye", "stop", "quit", "好的谢谢"]
        return exits.contains { text.contains($0) }
    }

    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }

    private func restartWakeDetector() {
        // Will be triggered from the owner (ContentView/AppState binding)
        // No-op here; ContentView observes phase and re-enables wake if needed
    }

    var callDurationString: String {
        let m = Int(callDuration) / 60
        let s = Int(callDuration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
