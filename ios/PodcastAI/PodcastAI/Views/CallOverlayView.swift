import SwiftUI

struct CallOverlayView: View {
    @Bindable var session: VoiceCallSession
    var onHangUp: () -> Void

    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 28) {
                // Duration
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                        .overlay(Circle().fill(Color.green).frame(width: 8, height: 8)
                            .scaleEffect(1.8).opacity(0.4)
                            .animation(.easeInOut(duration: 0.9).repeatForever(), value: true))
                    Text("通话中  \(session.callDurationString)")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Phase icon + animation
                PhaseIconView(phase: session.phase)
                    .frame(width: 120, height: 120)

                // Live transcript
                if !session.liveTranscript.isEmpty || !session.aiTranscript.isEmpty {
                    Text(session.phase == .speaking ? session.aiTranscript : session.liveTranscript)
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: session.liveTranscript + session.aiTranscript)
                }

                // Status label
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                // Hang up button
                Button(action: onHangUp) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 68, height: 68)
                        Image(systemName: "phone.down.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.vertical, 40)
        }
    }

    private var statusLabel: String {
        switch session.phase {
        case .idle:       return ""
        case .listening:  return "正在聆听…"
        case .processing: return "AI 思考中…"
        case .speaking:   return "AI 正在回答"
        }
    }
}

// MARK: – Phase animation icon

private struct PhaseIconView: View {
    var phase: VoiceCallSession.Phase
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer pulse ring (only during listening)
            if phase == .listening {
                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.6 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: pulse)
            }

            Circle()
                .fill(iconBackground)
                .frame(width: 90, height: 90)

            Image(systemName: iconName)
                .font(.system(size: 38))
                .foregroundStyle(.white)
        }
        .onAppear { pulse = true }
        .onChange(of: phase) { _, _ in pulse = true }
    }

    private var iconName: String {
        switch phase {
        case .idle:       return "waveform"
        case .listening:  return "mic.fill"
        case .processing: return "ellipsis"
        case .speaking:   return "speaker.wave.3.fill"
        }
    }

    private var iconBackground: Color {
        switch phase {
        case .listening:  return .accentColor
        case .speaking:   return .green
        default:          return Color(.systemGray3)
        }
    }
}
