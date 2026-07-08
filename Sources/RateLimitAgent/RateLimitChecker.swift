import Foundation

// MARK: - API Endpoints

enum OpenCodeAPI {
    static let baseURL = URL(string: "https://opencode.ai/zen/v1")!

    /// Makes a minimal request to check if the model is rate limited.
    /// Returns `nil` if the request succeeds (not rate limited),
    /// or the number of seconds to wait if rate limited.
    static func checkRateLimit(model: String, apiKey: String? = nil) async throws -> Int? {
        let url = baseURL.appending(path: "chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = apiKey {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 15

        // Minimal payload: 1 token response
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "."]],
            "max_tokens": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RateLimitError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            // Success — not rate limited
            return nil

        case 429:
            // Rate limited — parse Retry-After header
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                ?? httpResponse.value(forHTTPHeaderField: "retry-after")

            if let retryAfterStr = retryAfter, let seconds = Int(retryAfterStr) {
                return seconds
            }
            // Default fallback: 1 hour
            return 3600

        default:
            throw RateLimitError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - RateLimitChecker Wrapper

actor RateLimitChecker {
    private var cachedApiKey: String?
    private var keyLoadAttempted = false

    func checkRateLimit(model: String) async throws -> Int? {
        return try await OpenCodeAPI.checkRateLimit(model: model, apiKey: nil)
    }
}

// MARK: - Errors

enum RateLimitError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenCode API"
        case .httpError(let code):
            return "HTTP \(code) from OpenCode API"
        }
    }
}
