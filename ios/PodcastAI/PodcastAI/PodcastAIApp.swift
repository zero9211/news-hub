import SwiftUI

@main
struct PodcastAIApp: App {

    // ── Shared services (created once) ────────────────────────────
    private let appState = AppState()
    private let player   = PodcastPlayer()

    private let glm: GLMService
    private let tts  = VoiceResponder()
    private let vad  = VADRecorder()
    private let wake = WakeWordDetector()
    private let session: VoiceCallSession

    init() {
        glm = GLMService(apiKey: UserDefaults.standard.string(forKey: "pc_api_key") ?? "")
        session = VoiceCallSession(
            glm:          glm,
            tts:          tts,
            vad:          vad,
            wakeDetector: wake,
            player:       player
        )
        // Keep GLMService in sync with API key changes
        // (ContentView syncs on settings dismiss)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(session)
        }
    }
}
