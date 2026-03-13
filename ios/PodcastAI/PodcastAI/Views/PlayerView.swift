import SwiftUI

struct PlayerView: View {
    @Bindable var player: PodcastPlayer
    @State private var urlInput = ""
    @State private var rate: Float = 1.0

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

            // URL input
            HStack(spacing: 8) {
                TextField("粘贴播客 URL…", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Button("加载") {
                    loadURL()
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlInput.isEmpty)
            }
        }
        .padding()
    }

    // MARK: – Helpers

    private func skipButton(_ delta: Double, _ icon: String) -> some View {
        Button { player.skip(delta) } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
        .disabled(!player.isLoaded)
    }

    private func loadURL() {
        guard let url = URL(string: urlInput.trimmingCharacters(in: .whitespaces)) else { return }
        let name = url.deletingPathExtension().lastPathComponent
        player.load(url: url, name: name)
        player.play()
        urlInput = ""
        hideKeyboard()
    }

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
