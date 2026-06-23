import Defaults
import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Defaults.Serializable {
    case anthropic
    case openAI
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic:
            return "Anthropic"
        case .openAI:
            return "OpenAI"
        case .gemini:
            return "Gemini"
        }
    }
}
