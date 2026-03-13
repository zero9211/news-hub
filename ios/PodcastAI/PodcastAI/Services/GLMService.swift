import Foundation

/// Client for Zhipu AI (智谱AI) open.bigmodel.cn
/// Supports: streaming multi-turn chat + audio transcription (ASR)
final class GLMService {

    var apiKey: String

    private let chatURL  = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
    private let asrURL   = URL(string: "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: – Streaming Chat (SSE)

    /// Streams text chunks from GLM. Yields partial content deltas.
    func streamChat(messages: [Message]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var req = URLRequest(url: chatURL)
                    req.httpMethod = "POST"
                    req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
                    req.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")

                    let body: [String: Any] = [
                        "model":    "glm-4-plus",
                        "stream":   true,
                        "messages": messages.map { $0.apiDict }
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)

                    guard let http = response as? HTTPURLResponse else {
                        throw GLMError.invalidResponse
                    }
                    guard http.statusCode == 200 else {
                        // Try to read error body
                        var errData = Data()
                        for try await byte in bytes { errData.append(byte) }
                        let msg = String(data: errData, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                        throw GLMError.apiError(msg)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let chunk = parseSSEChunk(payload) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: – ASR Transcription

    /// Transcribes audio data (M4A/WAV) using glm-asr-2512.
    func transcribe(audioData: Data, language: String = "en-US") async throws -> String {
        let boundary = UUID().uuidString
        var req = URLRequest(url: asrURL)
        req.httpMethod = "POST"
        req.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendFormField(boundary: boundary, name: "model",  value: "glm-asr-2512")
        body.appendFormField(boundary: boundary, name: "stream", value: "false")
        body.appendFileField(boundary: boundary, name: "file", filename: "audio.m4a",
                             mimeType: "audio/m4a", data: audioData)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            return ""
        }
        return text
    }

    // MARK: – Helpers

    private func parseSSEChunk(_ payload: String) -> String? {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta   = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else { return nil }
        return content
    }

    enum GLMError: LocalizedError {
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:   return "服务器返回无效响应"
            case .apiError(let msg): return msg
            }
        }
    }
}

// MARK: – Multipart helpers

private extension Data {
    mutating func appendFormField(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendFileField(boundary: String, name: String,
                                  filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
