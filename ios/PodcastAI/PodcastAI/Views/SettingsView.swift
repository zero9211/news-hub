import SwiftUI

struct SettingsView: View {
    @Bindable var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var tempKey      = ""
    @State private var tempWakeWord = ""

    var body: some View {
        NavigationStack {
            Form {
                // API Key
                Section {
                    SecureField("GLM API Key（open.bigmodel.cn）", text: $tempKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("API 设置")
                } footer: {
                    Text("前往 open.bigmodel.cn 注册获取 API Key")
                }

                // Wake word
                Section {
                    TextField("唤醒词", text: $tempWakeWord)
                        .autocorrectionDisabled()
                } header: {
                    Text("唤醒词")
                } footer: {
                    Text("说出唤醒词即可免手动开始对话，例如"小艾"或"嘿小艾"")
                }

                // Language
                Section("语言设置") {
                    Picker("我的语言", selection: $state.userLang) {
                        Text("中文").tag("zh-CN")
                        Text("English (US)").tag("en-US")
                        Text("English (UK)").tag("en-GB")
                    }
                    Picker("播客语言（ASR）", selection: $state.podcastLang) {
                        Text("英语").tag("en-US")
                        Text("中文").tag("zh-CN")
                        Text("日语").tag("ja-JP")
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                tempKey      = state.apiKey
                tempWakeWord = state.wakeWord
            }
        }
    }

    private func save() {
        let key = tempKey.trimmingCharacters(in: .whitespaces)
        if !key.isEmpty { state.apiKey = key }

        let word = tempWakeWord.trimmingCharacters(in: .whitespaces)
        if !word.isEmpty { state.wakeWord = word }
    }
}
