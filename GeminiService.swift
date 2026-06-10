import Foundation

enum GeminiServiceError: Error {
    case invalidResponse
    case missingAPIKey
}

struct GeminiService {
    var apiKey: String?
    var modelName: String = "gemini-2.5-flash"

    func generateReply(
        prompt: String,
        mode: AssistantMode,
        imageData: Data? = nil
    ) async throws -> String {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.demoReply(prompt: prompt, mode: mode, hasImage: imageData != nil)
        }

        let systemInstruction = """
        You are Siri AI, a polished Apple-style assistant with a calm, concise tone.
        If the user asks for image analysis, describe the image clearly and mention the most important visible details first.
        If the user is speaking in voice mode, keep the response short and speakable.
        """

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)")!

        struct RequestBody: Encodable {
            struct Part: Encodable {
                var text: String?
                var inlineData: InlineData?

                init(text: String) {
                    self.text = text
                    self.inlineData = nil
                }

                init(imageData: Data, mimeType: String) {
                    self.text = nil
                    self.inlineData = InlineData(
                        mimeType: mimeType,
                        data: imageData.base64EncodedString()
                    )
                }
            }

            struct InlineData: Encodable {
                var mimeType: String
                var data: String
            }

            struct Content: Encodable {
                var role: String
                var parts: [Part]
            }

            struct GenerationConfig: Encodable {
                var temperature: Double = 0.7
                var maxOutputTokens: Int = 1024
            }

            struct SystemInstruction: Encodable {
                var parts: [Part]
            }

            var systemInstruction: SystemInstruction
            var contents: [Content]
            var generationConfig: GenerationConfig
        }

        struct ResponseBody: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        var text: String?
                    }

                    var parts: [Part]?
                }

                var content: Content?
            }

            var candidates: [Candidate]?
        }

        var userParts: [RequestBody.Part] = [RequestBody.Part(text: prompt)]
        if let imageData {
            userParts.append(RequestBody.Part(imageData: imageData, mimeType: "image/jpeg"))
        }

        let body = RequestBody(
            systemInstruction: .init(parts: [RequestBody.Part(text: systemInstruction)]),
            contents: [
                .init(role: "user", parts: userParts)
            ],
            generationConfig: .init()
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw GeminiServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        let text = decoded.candidates?
            .compactMap { $0.content?.parts?.compactMap { $0.text }.joined(separator: "\n") }
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let text, !text.isEmpty {
            return text
        }

        throw GeminiServiceError.invalidResponse
    }

    private static func demoReply(prompt: String, mode: AssistantMode, hasImage: Bool) -> String {
        switch mode {
        case .chat:
            return "I am ready. You asked: “\(prompt)”. Add a Gemini API key to switch from the demo reply to a real answer."
        case .vision:
            return hasImage
                ? "I can see the attached image and I am ready to analyze it once Gemini is connected."
                : "Please attach a photo or screenshot and I will describe it."
        case .voice:
            return "Voice mode is armed. When you add speech transcription, I will answer in a short, speakable format."
        }
    }
}

