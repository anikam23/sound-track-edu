import Foundation

// MARK: - API Response Models
private struct OpenAIResponse: Codable { let choices: [Choice] }
private struct Choice: Codable { let message: Message }
private struct Message: Codable { let content: String? }

enum AISummaryError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing OpenAI API key."
        case .invalidURL:    return "Invalid API URL."
        case .invalidResponse: return "Invalid response from API."
        case .apiError(let code, let msg): return "API Error \(code): \(msg)"
        case .noContent:     return "No content received from API."
        }
    }
}

/// Service for generating AI-powered summaries of transcripts using OpenAI API
@MainActor
class AISummaryService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 3.0 // simple local pacing

    init() {
        self.apiKey = Self.loadAPIKey()
    }

    private static func loadAPIKey() -> String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let key = dict["OPENAI_API_KEY"] as? String
        else { return "" }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generate a summary for the given transcript text
    func generateSummary(for transcript: String, subject: String, period: String) async -> String? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard !apiKey.isEmpty else {
            errorMessage = AISummaryError.missingAPIKey.localizedDescription
            return nil
        }

        // simple pacing to avoid burst limits
        if let last = lastRequestTime {
            let dt = Date().timeIntervalSince(last)
            if dt < minimumRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - dt) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()

        do {
            let summary = try await performAPICall(transcript: transcript, subject: subject, period: period)
            return summary
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }

    private func performAPICall(transcript: String, subject: String, period: String) async throws -> String {
        let prompt = createPrompt(for: transcript, subject: subject, period: period)

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You create concise, educational summaries of classroom transcripts focusing on key concepts, main topics, and useful review notes for students."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 400
        ]

        guard let url = URL(string: baseURL) else { throw AISummaryError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // retry on 429 with exponential backoff
        var attempt = 0
        let maxAttempts = 3
        var lastError: Error?

        while attempt < maxAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AISummaryError.invalidResponse
                }

                if http.statusCode == 200 {
                    let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    if let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !content.isEmpty {
                        return content
                    }
                    throw AISummaryError.noContent
                } else if http.statusCode == 429 {
                    attempt += 1
                    let backoff = pow(2.0, Double(attempt)) // 2s, 4s, ...
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw AISummaryError.apiError(http.statusCode, msg)
                }
            } catch {
                lastError = error
                attempt += 1
                if attempt >= maxAttempts { throw error }
                let backoff = pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            }
        }

        throw lastError ?? AISummaryError.invalidResponse
    }

    private func createPrompt(for transcript: String, subject: String, period: String) -> String {
        """
        Please create a concise summary for \(subject) (Period \(period)).

        Focus on:
        • Key concepts and topics discussed
        • Important information for students
        • Main learning objectives covered

        Transcript:
        \(transcript)

        Return a well-structured summary with short sections or bullets suitable for student review.
        """
    }
}
