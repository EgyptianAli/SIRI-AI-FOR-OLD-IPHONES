import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SiriAIActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: AssistantPhase
        var prompt: String
        var answerPreview: String
        var progress: Double
        var modeTitle: String
        var hasImage: Bool
        var isVoiceMode: Bool
        var updatedAt: Date
    }

    var conversationID: String
    var displayName: String
}

@available(iOS 16.1, *)
@MainActor
final class SiriAILiveActivityCoordinator: ObservableObject {
    static let shared = SiriAILiveActivityCoordinator()

    @Published private(set) var isEnabled: Bool = ActivityAuthorizationInfo().areActivitiesEnabled
    @Published private(set) var currentPhase: AssistantPhase = .idle

    private var activity: Activity<SiriAIActivityAttributes>?
    private var currentState: SiriAIActivityAttributes.ContentState?

    private init() {}

    func refreshAuthorization() {
        isEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func startSession(prompt: String, mode: AssistantMode, hasImage: Bool) async {
        refreshAuthorization()
        guard isEnabled else { return }

        if activity != nil {
            await endSession(finalAnswer: currentState?.answerPreview ?? "", dismissalPolicy: .immediate)
        }

        let attributes = SiriAIActivityAttributes(
            conversationID: UUID().uuidString,
            displayName: "Siri AI"
        )

        let initialPhase: AssistantPhase = {
            switch mode {
            case .chat: return .thinking
            case .vision: return .analyzingPhoto
            case .voice: return .listening
            }
        }()

        let state = SiriAIActivityAttributes.ContentState(
            phase: initialPhase,
            prompt: prompt,
            answerPreview: "Working on it...",
            progress: 0.18,
            modeTitle: mode.title,
            hasImage: hasImage,
            isVoiceMode: mode == .voice,
            updatedAt: .now
        )

        do {
            let launched = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(120), relevanceScore: 1),
                pushType: nil,
                style: .transient
            )
            activity = launched
            currentState = state
            currentPhase = state.phase
        } catch {
            activity = nil
        }
    }

    func update(
        phase: AssistantPhase,
        prompt: String? = nil,
        answerPreview: String? = nil,
        progress: Double? = nil,
        modeTitle: String? = nil,
        hasImage: Bool? = nil,
        isVoiceMode: Bool? = nil
    ) async {
        guard let activity, var state = currentState else { return }

        state.phase = phase
        if let prompt { state.prompt = prompt }
        if let answerPreview { state.answerPreview = answerPreview }
        if let progress { state.progress = progress }
        if let modeTitle { state.modeTitle = modeTitle }
        if let hasImage { state.hasImage = hasImage }
        if let isVoiceMode { state.isVoiceMode = isVoiceMode }
        state.updatedAt = .now

        await activity.update(
                ActivityContent(state: state, staleDate: Date().addingTimeInterval(120), relevanceScore: 1)
        )
        currentState = state
        currentPhase = phase
    }

    func endSession(finalAnswer: String? = nil, dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        guard let activity, let currentState else { return }

        let finalState = SiriAIActivityAttributes.ContentState(
            phase: .completed,
            prompt: currentState.prompt,
            answerPreview: finalAnswer ?? currentState.answerPreview,
            progress: 1,
            modeTitle: currentState.modeTitle,
            hasImage: currentState.hasImage,
            isVoiceMode: currentState.isVoiceMode,
            updatedAt: .now
        )

        do {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil, relevanceScore: 1),
                dismissalPolicy: dismissalPolicy
            )
        }

        self.activity = nil
        self.currentState = nil
        self.currentPhase = .completed
    }
}
