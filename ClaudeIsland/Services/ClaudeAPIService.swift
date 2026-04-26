import Foundation

struct APIResult {
    let text: String
    let inputTokens: Int
    let outputTokens: Int
    let rateLimit: RateLimitInfo
}

actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let endpoint   = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    private struct Body: Encodable {
        let model: String
        let max_tokens: Int
        let temperature: Double
        let system: String?
        let messages: [Msg]
        struct Msg: Encodable { let role: String; let content: String }
    }

    private struct Reply: Decodable {
        let content: [Block]
        let usage: Usage
        struct Block: Decodable { let type: String; let text: String }
        struct Usage: Decodable { let input_tokens: Int; let output_tokens: Int }
    }

    enum Err: LocalizedError {
        case noKey, badResponse, http(Int, String)
        var errorDescription: String? {
            switch self {
            case .noKey:           return "Kein API-Key. Bitte in Einstellungen eintragen."
            case .badResponse:     return "Ungültige Serverantwort."
            case .http(let c, _): return "HTTP \(c) – prüfe deinen API-Key."
            }
        }
    }

    func send(query: String, model: String, maxTokens: Int, temperature: Double,
              system: String?, apiKey: String) async throws -> APIResult {
        guard !apiKey.isEmpty else { throw Err.noKey }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        req.setValue(apiVersion,         forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONEncoder().encode(
            Body(model: model, max_tokens: maxTokens, temperature: temperature,
                 system: system?.isEmpty == false ? system : nil,
                 messages: [.init(role: "user", content: query)])
        )

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw Err.badResponse }
        guard http.statusCode == 200 else {
            throw Err.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        let decoded = try JSONDecoder().decode(Reply.self, from: data)
        let text    = decoded.content.first(where: { $0.type == "text" })?.text ?? "—"

        let rl = RateLimitInfo(
            requestsLimit:     intHeader(http, "anthropic-ratelimit-requests-limit"),
            requestsRemaining: intHeader(http, "anthropic-ratelimit-requests-remaining"),
            requestsReset:     http.value(forHTTPHeaderField: "anthropic-ratelimit-requests-reset"),
            tokensLimit:       intHeader(http, "anthropic-ratelimit-tokens-limit"),
            tokensRemaining:   intHeader(http, "anthropic-ratelimit-tokens-remaining"),
            tokensReset:       http.value(forHTTPHeaderField: "anthropic-ratelimit-tokens-reset")
        )

        return APIResult(text: text,
                         inputTokens: decoded.usage.input_tokens,
                         outputTokens: decoded.usage.output_tokens,
                         rateLimit: rl)
    }

    private func intHeader(_ r: HTTPURLResponse, _ key: String) -> Int? {
        r.value(forHTTPHeaderField: key).flatMap(Int.init)
    }
}
