import Foundation
import Combine

struct RateLimitInfo {
    var requestsLimit: Int?
    var requestsRemaining: Int?
    var requestsReset: String?
    var tokensLimit: Int?
    var tokensRemaining: Int?
    var tokensReset: String?

    var requestsPercent: Double? {
        guard let lim = requestsLimit, let rem = requestsRemaining, lim > 0 else { return nil }
        return Double(rem) / Double(lim)
    }
    var tokensPercent: Double? {
        guard let lim = tokensLimit, let rem = tokensRemaining, lim > 0 else { return nil }
        return Double(rem) / Double(lim)
    }
}

final class UsageStore: ObservableObject {
    static let shared = UsageStore()

    @Published var sessionInputTokens  = 0
    @Published var sessionOutputTokens = 0
    @Published var sessionRequests     = 0
    @Published var rateLimit           = RateLimitInfo()

    private let ud = UserDefaults.standard
    private var todayKey: String { "tokens_\(todayString)" }
    private var todayString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    @Published var todayTokens: Int = 0

    private init() {
        todayTokens = ud.integer(forKey: "tokens_\(todayString)")
    }

    func record(inputTokens: Int, outputTokens: Int, rateLimit: RateLimitInfo) {
        let total = inputTokens + outputTokens
        sessionInputTokens  += inputTokens
        sessionOutputTokens += outputTokens
        sessionRequests     += 1
        todayTokens         += total
        ud.set(todayTokens, forKey: todayKey)
        self.rateLimit = rateLimit
    }

    func resetSession() {
        sessionInputTokens  = 0
        sessionOutputTokens = 0
        sessionRequests     = 0
    }

    var sessionTotal: Int { sessionInputTokens + sessionOutputTokens }
}
