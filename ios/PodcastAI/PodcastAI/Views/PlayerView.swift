import SwiftUI

struct PlayerView: View {
    @Bindable var player: PodcastPlayer
    @State private var urlInput     = ""
    @State private var rate: Float  = 1.0

    // RSS feed state
    @State private var isLoadingFeed = false
    @State private var episodes: [PodcastEpisode] = []
    @State private var showEpisodes  = false
    @State private var feedError: String?

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text(player.title.isEmpty ? "未加载播客" : player.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(player.isLoaded ? .primary : .secondary)

            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor)
                            .frame(width: player.duration > 0
                                   ? geo.size.width * CGFloat(player.currentTime / player.duration)
                                   : 0, height: 4)
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let ratio = value.location.x / geo.size.width
                            player.seek(to: player.duration * Double(ratio))
                        })
                }
                .frame(height: 20)

                HStack {
                    Text(formatTime(player.currentTime)).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTime(player.duration)).font(.caption).foregroundStyle(.secondary)
                }
            }

            // Transport controls
            HStack(spacing: 12) {
                skipButton(-30, "gobackward.30")
                skipButton(-10, "gobackward.10")

                Button {
                    player.isPlaying ? player.pause() : player.play()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(!player.isLoaded)

                skipButton(10, "goforward.10")
                skipButton(30, "goforward.30")
            }

            // Speed selector
            Picker("Speed", selection: $rate) {
                Text("0.75×").tag(Float(0.75))
                Text("1.0×").tag(Float(1.0))
                Text("1.25×").tag(Float(1.25))
                Text("1.5×").tag(Float(1.5))
                Text("2.0×").tag(Float(2.0))
            }
            .pickerStyle(.segmented)
            .onChange(of: rate) { _, newVal in player.setRate(newVal) }

            // URL / Feed input
            HStack(spacing: 8) {
                TextField("粘贴播客 URL 或 RSS Feed…", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                if isLoadingFeed {
                    ProgressView()
                        .frame(width: 60)
                } else {
                    Button("加载") { handleLoad() }
                        .buttonStyle(.borderedProminent)
                        .disabled(urlInput.isEmpty)
                }
            }

            if let err = feedError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .sheet(isPresented: $showEpisodes) {
            EpisodeListView(episodes: episodes) { episode in
                player.load(url: episode.audioURL, name: episode.title)
                player.play()
                showEpisodes = false
            }
        }
    }

    // MARK: – Helpers

    private func handleLoad() {
        guard let url = URL(string: urlInput.trimmingCharacters(in: .whitespaces)) else { return }
        feedError = nil
        hideKeyboard()

        // Heuristic: treat as RSS if path ends with xml/rss/feed, or try XML parse
        let path = url.path.lowercased()
        let looksLikeFeed = path.hasSuffix(".xml") || path.hasSuffix(".rss")
            || path.contains("feed") || path.contains("rss")

        if looksLikeFeed {
            loadFeed(url: url)
        } else {
            // Direct audio URL
            let name = url.deletingPathExtension().lastPathComponent
            player.load(url: url, name: name)
            player.play()
            urlInput = ""
        }
    }

    private func loadFeed(url: URL) {
        isLoadingFeed = true
        Task {
            do {
                let result = try await RSSParser.fetch(feedURL: url)
                await MainActor.run {
                    isLoadingFeed = false
                    if result.isEmpty {
                        feedError = "未找到单集，请确认这是播客 RSS Feed"
                    } else {
                        episodes    = result
                        showEpisodes = true
                        urlInput    = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingFeed = false
                    feedError = "加载失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func skipButton(_ delta: Double, _ icon: String) -> some View {
        Button { player.skip(delta) } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
        .disabled(!player.isLoaded)
    }

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let m   = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

// MARK: – Episode list sheet

struct EpisodeListView: View {
    let episodes: [PodcastEpisode]
    let onSelect: (PodcastEpisode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(episodes) { ep in
                Button {
                    onSelect(ep)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ep.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        HStack {
                            if !ep.duration.isEmpty {
                                Label(formatDuration(ep.duration), systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !ep.pubDate.isEmpty {
                                Text(shortDate(ep.pubDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("选择单集（\(episodes.count)集）")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    /// Converts "3605" seconds or "01:00:05" → "1:00:05"
    private func formatDuration(_ raw: String) -> String {
        if let secs = Double(raw), secs > 0 {
            let h = Int(secs) / 3600
            let m = (Int(secs) % 3600) / 60
            let s = Int(secs) % 60
            return h > 0
                ? String(format: "%d:%02d:%02d", h, m, s)
                : String(format: "%d:%02d", m, s)
        }
        return raw  // already formatted string
    }

    /// Trims RFC-822 pubDate to just "dd MMM yyyy"
    private func shortDate(_ raw: String) -> String {
        let parts = raw.split(separator: " ")
        guard parts.count >= 4 else { return raw }
        return "\(parts[1]) \(parts[2]) \(parts[3])"
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
