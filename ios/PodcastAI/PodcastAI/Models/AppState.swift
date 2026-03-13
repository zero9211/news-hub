import Foundation
import Observation

@Observable
class AppState {
    // ── Settings (persisted) ──────────────────────────────────────
    var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "pc_api_key") }
    }
    var wakeWord: String {
        didSet { UserDefaults.standard.set(wakeWord, forKey: "pc_wake_word") }
    }
    /// Language for user voice input (SFSpeechRecognizer)
    var userLang: String {
        didSet { UserDefaults.standard.set(userLang, forKey: "pc_user_lang") }
    }
    /// Language for podcast ASR (GLM glm-asr-2512)
    var podcastLang: String {
        didSet { UserDefaults.standard.set(podcastLang, forKey: "pc_podcast_lang") }
    }

    // ── Transient UI state ────────────────────────────────────────
    var wakeEnabled: Bool = false
    var showSettings: Bool = false

    init() {
        apiKey     = UserDefaults.standard.string(forKey: "pc_api_key")     ?? ""
        wakeWord   = UserDefaults.standard.string(forKey: "pc_wake_word")   ?? "小艾"
        userLang   = UserDefaults.standard.string(forKey: "pc_user_lang")   ?? "zh-CN"
        podcastLang = UserDefaults.standard.string(forKey: "pc_podcast_lang") ?? "en-US"
    }
}
