import Foundation

@MainActor
final class ClaudeWidgetModel: ObservableObject {
    @Published var query = ""
    @Published var messages: [(q: String, r: String, tokens: Int)] = []
    @Published var isThinking = false
    @Published var errorMsg: String? = nil

    func ask() {
        guard !query.isEmpty, !isThinking else { return }
        let q = query; query = ""; isThinking = true; errorMsg = nil
        Task {
            let s = SettingsStore.shared
            do {
                let result = try await ClaudeAPIService.shared.send(
                    query: q, model: s.selectedModel.rawValue,
                    maxTokens: s.maxTokens, temperature: s.temperature,
                    system: s.systemPrompt, apiKey: s.apiKey)
                UsageStore.shared.record(inputTokens: result.inputTokens,
                                         outputTokens: result.outputTokens,
                                         rateLimit: result.rateLimit)
                messages.append((q: q, r: result.text,
                                  tokens: result.inputTokens + result.outputTokens))
            } catch {
                errorMsg = error.localizedDescription
                messages.append((q: q, r: "Fehler: \(error.localizedDescription)", tokens: 0))
            }
            isThinking = false
        }
    }
}
