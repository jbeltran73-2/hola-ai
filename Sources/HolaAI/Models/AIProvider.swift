import Foundation

/// Speech-to-text provider
enum STTProvider: String, CaseIterable, Identifiable {
    case xai = "xAI Grok"
    case groq = "Groq"
    case openrouter = "OpenRouter"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .xai:
            return "https://api.x.ai/v1/stt"
        case .groq:
            return "https://api.groq.com/openai/v1/audio/transcriptions"
        case .openrouter:
            return "https://openrouter.ai/api/v1/chat/completions"
        }
    }

    var defaultModel: String {
        switch self {
        case .xai:
            // xAI STT endpoint does not take a model field; label for Preferences only
            return "grok-stt"
        case .groq:
            return "whisper-large-v3-turbo"
        case .openrouter:
            return "openai/whisper-1"
        }
    }

    var keychainAccount: String {
        switch self {
        case .xai: return "xai-api-key"
        case .groq: return "groq-api-key"
        case .openrouter: return "openrouter-api-key"
        }
    }

    /// Whether the provider accepts a free-form model string in Preferences
    var supportsCustomModel: Bool {
        switch self {
        case .xai: return false
        case .groq, .openrouter: return true
        }
    }

    var helpText: String {
        switch self {
        case .xai:
            return "Grok STT: high accuracy, low latency, 25 languages, automatic filler removal. Get a key at console.x.ai."
        case .groq:
            return "Groq uses native Whisper API (fast). Best for low-cost Whisper transcription."
        case .openrouter:
            return "OpenRouter uses audio via chat completions (slower, model-dependent)."
        }
    }
}

/// LLM provider for text processing
enum LLMProvider: String, CaseIterable, Identifiable {
    case xai = "xAI Grok"
    case cerebras = "Cerebras"
    case groq = "Groq"
    case openrouter = "OpenRouter"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .xai:
            return "https://api.x.ai/v1/chat/completions"
        case .cerebras:
            return "https://api.cerebras.ai/v1/chat/completions"
        case .groq:
            return "https://api.groq.com/openai/v1/chat/completions"
        case .openrouter:
            return "https://openrouter.ai/api/v1/chat/completions"
        }
    }

    var defaultModel: String {
        switch self {
        case .xai:
            return "grok-4-1-fast-non-reasoning"
        case .cerebras:
            return "gpt-oss-120b"
        case .groq:
            return "llama-3.3-70b-versatile"
        case .openrouter:
            return "openai/gpt-4o-mini"
        }
    }

    /// Default for prompt enhancement (more capable when available)
    var defaultPromptModel: String {
        switch self {
        case .xai:
            return "grok-4"
        default:
            return defaultModel
        }
    }

    var keychainAccount: String {
        switch self {
        case .xai: return "xai-api-key"
        case .cerebras: return "cerebras-api-key"
        case .groq: return "groq-api-key"
        case .openrouter: return "openrouter-api-key"
        }
    }
}
