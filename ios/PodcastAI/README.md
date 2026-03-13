# PodcastAI — iOS 原生 AI 播客伴侣

## 功能
- 🎙️ 说「小艾」（可自定义）唤醒，无需触屏
- 📞 豆包式"打电话"多轮语音对话
- 🤖 AI 语音回答（TTS），不显示文字气泡
- 🎧 播客暂停 → 对话 → 自动继续
- 🧠 最近 5 分钟播客音频上下文（自动 ASR）

---

## 构建步骤

### 方法 A：使用 XcodeGen（推荐）
```bash
# 安装 XcodeGen（需要 Homebrew）
brew install xcodegen

# 在项目目录运行
cd ios/PodcastAI
xcodegen generate

# 打开生成的 .xcodeproj
open PodcastAI.xcodeproj
```

### 方法 B：手动在 Xcode 中创建
1. 打开 Xcode → File → New → Project → iOS App
2. 命名 `PodcastAI`，Bundle ID: `com.podcastai.app`
3. Interface: SwiftUI，Language: Swift
4. 删除默认的 `ContentView.swift`
5. 将 `PodcastAI/` 下所有 `.swift` 文件和 `Info.plist` 拖入 Xcode 项目
6. 在 Target → Info 中添加：
   - `NSMicrophoneUsageDescription`
   - `NSSpeechRecognitionUsageDescription`
   - `UIBackgroundModes = [audio]`

---

## 配置
打开 App → 右上角设置（⚙️）：
- 填写 GLM API Key（[open.bigmodel.cn](https://open.bigmodel.cn) 获取）
- 设置唤醒词（默认「小艾」）
- 选择播客语言（英语/中文等）

---

## 使用方法
1. 粘贴播客 MP3/M4A URL，点击「加载」
2. 开启「唤醒词模式」开关
3. 播放播客，说「小艾」
4. 播客暂停，说出你的问题（如「gonna 是什么意思」）
5. 等待 AI 语音回答
6. 可继续多轮追问，说「再见」或点击挂断退出

---

## 技术架构
```
PodcastAIApp
├── AppState (@Observable)          — 设置持久化
├── VoiceCallSession (@Observable)  — 对话状态机
│   ├── WakeWordDetector            — 唤醒词监听（SFSpeechRecognizer 循环）
│   ├── VADRecorder                 — 录音 + 静音检测（RMS VAD）
│   ├── VoiceResponder              — TTS（AVSpeechSynthesizer 流式）
│   ├── GLMService                  — 智谱AI API（SSE 流式）
│   └── PodcastPlayer (AVPlayer)    — 播放器 + 环境录音缓冲
└── AudioEngineManager (singleton)  — 共享 AVAudioEngine + 麦克风 tap
```

---

## 系统要求
- iOS 17.0+
- Xcode 15+
- 真机测试（模拟器无麦克风）
- Apple Developer Account（用于真机签名）
