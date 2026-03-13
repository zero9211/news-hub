import AVFoundation

/// Central manager for the shared AVAudioEngine and AVAudioSession.
/// Provides a single microphone tap that routes audio to whoever subscribes.
final class AudioEngineManager {
    static let shared = AudioEngineManager()

    let engine = AVAudioEngine()

    /// Called with every mic buffer. Set by WakeWordDetector or VADRecorder.
    var micBufferHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    private var isTapInstalled = false
    private var isEngineRunning = false

    private init() {
        configureSession()
    }

    // MARK: – Session

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            print("[AudioEngineManager] Session config failed: \(error)")
        }
    }

    // MARK: – Engine lifecycle

    func startEngine() {
        guard !isEngineRunning else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("[AudioEngineManager] Engine start failed: \(error)")
        }
    }

    func stopEngine() {
        engine.stop()
        isEngineRunning = false
    }

    // MARK: – Mic tap (single tap, shared)

    func installMicTap() {
        guard !isTapInstalled else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.micBufferHandler?(buffer, time)
        }
        isTapInstalled = true
        startEngine()
    }

    func removeMicTap() {
        guard isTapInstalled else { return }
        engine.inputNode.removeTap(onBus: 0)
        isTapInstalled = false
    }

    var micFormat: AVAudioFormat {
        engine.inputNode.outputFormat(forBus: 0)
    }
}
