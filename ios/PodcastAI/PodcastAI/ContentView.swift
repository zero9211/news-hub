import SwiftUI
import Speech

struct ContentView: View {
    @Environment(AppState.self) private var state
    @Environment(VoiceCallSession.self) private var session

    @State private var permissionsGranted = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    // ── Player ────────────────────────────────────────
                    PlayerView(player: session.player)
                        .padding(.top, 8)

                    Divider().padding(.vertical, 8)

                    // ── Wake word toggle ──────────────────────────────
                    wakeWordRow

                    // ── Permissions hint ─────────────────────────────
                    if !permissionsGranted {
                        permissionsHint
                    }

                    Spacer()
                }
                .navigationTitle("AI 播客伴侣")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            state.showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }

            // ── Full-screen call overlay ──────────────────────────────
            if session.phase != .idle {
                CallOverlayView(session: session) {
                    session.endCall(sayFarewell: false)
                    if state.wakeEnabled { enableWakeMode() }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: session.phase == .idle)
            }
        }
        .sheet(isPresented: Bindable(state).showSettings) {
            SettingsView(state: state)
                .onDisappear { syncServices() }
        }
        .onAppear {
            requestPermissions()
        }
        // Re-enable wake detector after a call ends
        .onChange(of: session.phase) { _, newPhase in
            if newPhase == .idle && state.wakeEnabled {
                enableWakeMode()
            }
        }
        .alert("需要权限", isPresented: $showPermissionAlert) {
            Button("前往设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在设置中允许麦克风和语音识别权限，以使用语音对话功能。")
        }
    }

    // MARK: – Wake row

    private var wakeWordRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("唤醒词模式")
                    .font(.headline)
                Text("说「\(state.wakeWord)」开始通话")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { state.wakeEnabled },
                set: { on in
                    state.wakeEnabled = on
                    on ? enableWakeMode() : disableWakeMode()
                }
            ))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var permissionsHint: some View {
        Button {
            requestPermissions()
        } label: {
            Label("点击授权麦克风 & 语音识别", systemImage: "mic.badge.xmark")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.top, 8)
    }

    // MARK: – Permissions

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    showPermissionAlert = true
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        permissionsGranted = granted
                        if !granted { showPermissionAlert = true }
                    }
                }
            }
        }
    }

    // MARK: – Wake mode

    private func enableWakeMode() {
        syncServices()
        session.wakeDetector.start(
            wakeWord: state.wakeWord,
            language: state.userLang
        )
    }

    private func disableWakeMode() {
        session.wakeDetector.stop()
    }

    private func syncServices() {
        session.userLang    = state.userLang
        session.podcastLang = state.podcastLang
    }
}
