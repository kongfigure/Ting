import Foundation

// Locale identifiers verified against SFSpeechRecognizer.supportedLocales()
// (checked at runtime — see SpeechRecognizer.logLanguageSupport()).
enum LearningLanguage: String, CaseIterable, Identifiable {
    case cantonese
    case mandarinSimplified
    case mandarinTraditional
    case spanish
    case french
    case korean
    case japanese
    case german
    case portuguese

    var id: String { rawValue }

    /// Human-readable name passed to the Claude translation prompt.
    var apiName: String {
        switch self {
        case .cantonese: return "Cantonese"
        case .mandarinSimplified: return "Mandarin Chinese (Simplified)"
        case .mandarinTraditional: return "Mandarin Chinese (Traditional)"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .korean: return "Korean"
        case .japanese: return "Japanese"
        case .german: return "German"
        case .portuguese: return "Portuguese"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .cantonese: return "zh-HK"
        case .mandarinSimplified: return "zh-CN"
        case .mandarinTraditional: return "zh-TW"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .korean: return "ko-KR"
        case .japanese: return "ja-JP"
        case .german: return "de-DE"
        case .portuguese: return "pt-BR"
        }
    }

    /// Short native name for the direction toggle.
    var nativeName: String {
        switch self {
        case .cantonese: return "廣東話"
        case .mandarinSimplified: return "普通话"
        case .mandarinTraditional: return "國語"
        case .spanish: return "Español"
        case .french: return "Français"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        }
    }

    var displayName: String {
        switch self {
        case .cantonese: return "Cantonese 廣東話"
        case .mandarinSimplified: return "Mandarin 普通话 (Simplified)"
        case .mandarinTraditional: return "Mandarin 國語 (Traditional)"
        case .spanish: return "Spanish Español"
        case .french: return "French Français"
        case .korean: return "Korean 한국어"
        case .japanese: return "Japanese 日本語"
        case .german: return "German Deutsch"
        case .portuguese: return "Portuguese Português"
        }
    }
}
