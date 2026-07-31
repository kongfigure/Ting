import Foundation

// MARK: - Response structs (match your prompt's JSON shape)

struct TranslationResult: Codable {
    let translatedText: String
    let romanization: String?
    let category: String
    let notableWords: [NotableWord]

    enum CodingKeys: String, CodingKey {
        case translatedText = "translated_text"
        case romanization
        case category
        case notableWords = "notable_words"
    }
}

struct NotableWord: Codable {
    let word: String
    let romanization: String
    let meaning: String
    let usageNote: String

    enum CodingKeys: String, CodingKey {
        case word, romanization, meaning
        case usageNote = "usage_note"
    }
}

// Claude's raw API response wrapper
struct ClaudeAPIResponse: Codable {
    let content: [ContentBlock]
    struct ContentBlock: Codable {
        let text: String
    }
}

enum ClaudeAPIError: LocalizedError {
    case missingAPIKey
    case httpError(status: Int, body: String)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "CLAUDE_API_KEY is empty — check Secrets.xcconfig / Info.plist wiring."
        case .httpError(let status, let body):
            return "Claude API returned HTTP \(status): \(body)"
        case .malformedResponse:
            return "Could not parse Claude's response as TranslationResult JSON."
        }
    }
}

// MARK: - Service

class ClaudeAPIService {
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String ?? ""
    }

    func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> TranslationResult {
        guard !apiKey.isEmpty else { throw ClaudeAPIError.missingAPIKey }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        You are a translation assistant for a language-learning app. The user speaks \(sourceLanguage) and is learning \(targetLanguage).

        Translate the following text from \(sourceLanguage) to \(targetLanguage): "\(text)"

        Respond with ONLY valid JSON, no other text, in exactly this format:
        {
          "translated_text": "the translation",
          "romanization": "romanized pronunciation, or null if not applicable",
          "category": "one of: food, work, shows, school, general",
          "notable_words": [
            {"word": "...", "romanization": "...", "meaning": "...", "usage_note": "..."}
          ]
        }

        Only include 0-2 genuinely useful notable_words.
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ClaudeAPIError.httpError(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? "<unreadable>"
            )
        }

        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        guard let responseText = apiResponse.content.first?.text else {
            throw ClaudeAPIError.malformedResponse
        }

        // Strip markdown code fences in case the model wraps its JSON
        let cleaned = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeAPIError.malformedResponse
        }

        return try JSONDecoder().decode(TranslationResult.self, from: jsonData)
    }

    // ⚠️ DEMO FALLBACK — FAKE DATA. Returned when the real API call fails
    // (e.g. no API credits). Remove before shipping anything real.
    static func mockResult(for text: String) -> TranslationResult {
        TranslationResult(
            translatedText: "唔該，兩籠蝦餃同一籠燒賣。",
            romanization: "m4 goi1, loeng5 lung4 haa1 gaau2 tung4 jat1 lung4 siu1 maai2",
            category: "food",
            notableWords: [
                NotableWord(
                    word: "蝦餃",
                    romanization: "haa1 gaau2",
                    meaning: "shrimp dumpling (har gow)",
                    usageNote: "Classic dim sum order — measure word is 籠 (steamer basket)."
                )
            ]
        )
    }
}
