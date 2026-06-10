import Foundation
import PhotosUI

@MainActor
final class SiriAIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Hello, I am Siri AI. Ask me anything, drop in a photo, or switch to voice mode.")
    ]
    @Published var draftText: String = ""
    @Published var selectedMode: AssistantMode = .chat
    @Published var attachedImageData: Data?
    @Published var attachedImageName: String?
    @Published var isSending = false
    @Published var lastError: String?
    @Published var voiceTranscript: String = ""
    @Published var isVoiceTranscribing = false
    @Published var voicePermissionError: String?
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Self.apiKeyKey) }
    }
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: Self.modelKey) }
    }

    private static let apiKeyKey = "siri_ai_gemini_api_key"
    private static let modelKey = "siri_ai_gemini_model"
    private let voiceTranscriptionManager = VoiceTranscriptionManager()

    init() {
        let savedKey = UserDefaults.standard.string(forKey: Self.apiKeyKey) ?? AppSecrets.geminiAPIKey
        let savedModel = UserDefaults.standard.string(forKey: Self.modelKey) ?? "gemini-2.5-flash"
        self.apiKey = savedKey
        self.modelName = savedModel
    }

    func attachPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                attachedImageData = data
                attachedImageName = item.itemIdentifier ?? "Selected image"
                selectedMode = .vision
            }
        } catch {
            lastError = "Could not load the selected image."
        }
    }

    func clearAttachment() {
        attachedImageData = nil
        attachedImageName = nil
    }

    func startVoiceTranscription() async {
        selectedMode = .voice
        await voiceTranscriptionManager.startListening { [weak self] partialText in
            self?.draftText = partialText
            self?.voiceTranscript = partialText
            self?.isVoiceTranscribing = true
        }

        isVoiceTranscribing = voiceTranscriptionManager.isListening
        voiceTranscript = voiceTranscriptionManager.transcript
        voicePermissionError = voiceTranscriptionManager.errorMessage
        if let error = voiceTranscriptionManager.errorMessage {
            lastError = error
        }
    }

    func stopVoiceTranscription() {
        voiceTranscriptionManager.stopListening()
        isVoiceTranscribing = false
        voicePermissionError = voiceTranscriptionManager.errorMessage
        if !voiceTranscriptionManager.transcript.isEmpty {
            draftText = voiceTranscriptionManager.transcript
            voiceTranscript = voiceTranscriptionManager.transcript
        }
    }

    func send() async {
        let prompt = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasImage = attachedImageData != nil

        guard !prompt.isEmpty || hasImage else { return }
        guard !isSending else { return }

        isSending = true
        lastError = nil

        let userText = prompt.isEmpty ? (selectedMode == .vision ? "Analyze this image." : "Hello") : prompt
        messages.append(ChatMessage(role: .user, text: userText, imageData: attachedImageData))
        draftText = ""

        if #available(iOS 16.1, *) {
            await SiriAILiveActivityCoordinator.shared.startSession(
                prompt: userText,
                mode: selectedMode,
                hasImage: hasImage
            )

            await SiriAILiveActivityCoordinator.shared.update(
                phase: selectedMode == .vision ? .analyzingPhoto : (selectedMode == .voice ? .listening : .thinking),
                prompt: userText,
                answerPreview: "Working...",
                progress: 0.25,
                modeTitle: selectedMode.title,
                hasImage: hasImage,
                isVoiceMode: selectedMode == .voice
            )
        }

        do {
            let reply = try await GeminiService(apiKey: apiKey, modelName: modelName).generateReply(
                prompt: userText,
                mode: selectedMode,
                imageData: attachedImageData
            )

            if #available(iOS 16.1, *) {
                await SiriAILiveActivityCoordinator.shared.update(
                    phase: .responding,
                    answerPreview: String(reply.prefix(120)),
                    progress: 0.85
                )
            }

            messages.append(ChatMessage(role: .assistant, text: reply))

            if #available(iOS 16.1, *) {
                await SiriAILiveActivityCoordinator.shared.endSession(finalAnswer: reply, dismissalPolicy: .after(Date().addingTimeInterval(60)))
            }
        } catch {
            lastError = "Gemini request failed. Check your API key or network connection."
            messages.append(ChatMessage(role: .assistant, text: "I hit a network or API error. Please check your Gemini key and try again."))

            if #available(iOS 16.1, *) {
                await SiriAILiveActivityCoordinator.shared.endSession(finalAnswer: "Request failed.", dismissalPolicy: .default)
            }
        }

        clearAttachment()
        stopVoiceTranscription()
        isSending = false
    }

    func setAPIKey(_ newValue: String) {
        apiKey = newValue
    }

    func setModelName(_ newValue: String) {
        modelName = newValue
    }
}
