import AVFoundation
import Foundation
import Observation

/// AVPlayer-based podcast player.
/// Also runs a background mic-tap recording to capture ambient/room audio
/// (podcast speaker bleed) for AI context. Headphone users will not benefit
/// from audio capture — position-only context is used as fallback.
@Observable
final class PodcastPlayer: NSObject {

    // ── Playback state ──────────────────────────────────────────────
    var isPlaying   = false
    var currentTime = 0.0
    var duration    = 0.0
    var title       = ""
    var isLoaded    = false

    // ── Private ─────────────────────────────────────────────────────
    private var player: AVPlayer?
    private var timeObserver: Any?

    // Rolling ambient capture (mic records speaker bleed while playing)
    // Each chunk = one AVAudioRecorder file ≈ 10s
    private var captureChunks: [URL] = []         // oldest → newest
    private var captureRecorder: AVAudioRecorder?
    private var captureTimer: Timer?
    private let captureChunkDuration: TimeInterval = 10   // seconds per chunk
    private let maxChunks = 30                            // 5 minutes

    // MARK: – Public API

    func load(url: URL, name: String) {
        stop()
        title = name.isEmpty ? url.lastPathComponent : name
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        // Observe duration once loaded
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        Task {
            if let dur = try? await item.asset.load(.duration).seconds, dur.isFinite {
                await MainActor.run { self.duration = dur }
            }
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        isLoaded = true
    }

    func play() {
        player?.play()
        isPlaying = true
        startAmbientCapture()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopAmbientCapture()
    }

    func stop() {
        pause()
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        player = nil
        isLoaded = false
        currentTime = 0
        duration    = 0
        title       = ""
    }

    func seek(to seconds: Double) {
        let t = CMTime(seconds: max(0, min(seconds, duration)), preferredTimescale: 600)
        player?.seek(to: t)
    }

    func skip(_ delta: Double) {
        seek(to: currentTime + delta)
    }

    func setRate(_ rate: Float) {
        player?.rate = rate
    }

    // MARK: – Ambient audio capture

    private func startAmbientCapture() {
        stopAmbientCapture()
        recordNextChunk()
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureChunkDuration, repeats: true) { [weak self] _ in
            self?.recordNextChunk()
        }
    }

    private func stopAmbientCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        captureRecorder?.stop()
        captureRecorder = nil
    }

    private func recordNextChunk() {
        captureRecorder?.stop()

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("podcast_chunk_\(Date().timeIntervalSince1970).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey:         kAudioFormatMPEG4AAC,
            AVSampleRateKey:       16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey:   32000
        ]

        guard let rec = try? AVAudioRecorder(url: tmpURL, settings: settings) else { return }
        rec.record()
        captureRecorder = rec

        captureChunks.append(tmpURL)
        if captureChunks.count > maxChunks {
            let old = captureChunks.removeFirst()
            try? FileManager.default.removeItem(at: old)
        }
    }

    /// Returns the raw M4A data of the last `seconds` of ambient recording.
    /// Returns nil if no capture data is available.
    func getRecentAmbientData(seconds: Double = 30) -> Data? {
        let needed = Int(ceil(seconds / captureChunkDuration))
        let recent = captureChunks.suffix(needed)
        guard !recent.isEmpty else { return nil }

        // For a single file, return its data; for multiple, return the last one
        // (GLM ASR can handle the last chunk; multi-chunk concat is a future improvement)
        return try? Data(contentsOf: recent.last!)
    }

    var positionString: String {
        "\(formatTime(currentTime)) / \(formatTime(duration))"
    }

    // MARK: – Helpers

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite else { return "0:00" }
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }

    @objc private func playerItemDidReachEnd() {
        DispatchQueue.main.async { self.isPlaying = false }
    }
}
