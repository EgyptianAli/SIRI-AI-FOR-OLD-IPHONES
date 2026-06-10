import Foundation

enum AssistantMode: String, CaseIterable, Codable, Identifiable {
    case chat
    case vision
    case voice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: return "Chat"
        case .vision: return "Analyze Photo"
        case .voice: return "Voice"
        }
    }

    var subtitle: String {
        switch self {
        case .chat: return "Fast text answers"
        case .vision: return "Explain images and screenshots"
        case .voice: return "Hands-free conversation"
        }
    }

    var iconName: String {
        switch self {
        case .chat: return "sparkles"
        case .vision: return "photo.on.rectangle.angled"
        case .voice: return "waveform"
        }
    }

    var liveActivityLabel: String {
        switch self {
        case .chat: return "Thinking"
        case .vision: return "Analyzing"
        case .voice: return "Listening"
        }
    }
}

enum AssistantPhase: String, Codable, Hashable {
    case idle
    case thinking
    case analyzingPhoto
    case listening
    case responding
    case completed

    var title: String {
        switch self {
        case .idle: return "Idle"
        case .thinking: return "Thinking"
        case .analyzingPhoto: return "Analyzing photo"
        case .listening: return "Listening"
        case .responding: return "Responding"
        case .completed: return "Ready"
        }
    }

    var symbolName: String {
        switch self {
        case .idle: return "circle"
        case .thinking: return "sparkles"
        case .analyzingPhoto: return "camera.viewfinder"
        case .listening: return "waveform"
        case .responding: return "bubble.left.and.bubble.right.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable, Hashable {
        case user
        case assistant
    }

    var id = UUID()
    var role: Role
    var text: String
    var date: Date = .now
    var imageData: Data?
}

