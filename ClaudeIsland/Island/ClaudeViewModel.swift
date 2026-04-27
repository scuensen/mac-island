import AppKit

enum Phase: Equatable { case idle, thinking, done, error(String) }

@MainActor
final class ClaudeViewModel: ObservableObject {
    @Published var query    = ""
    @Published var messages: [(q: String, r: String, tokens: Int)] = []
    @Published var phase: Phase = .idle
    @Published var isExpanded = false

    var onResize: ((NSSize) -> Void)?
    private var clickMonitor: Any?
    private var autoCollapseTask: Task<Void, Never>?

    static let collapsed = NSSize(width: 280, height: 44)
    static let expanded  = NSSize(width: 520, height: 400)

    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        onResize?(Self.expanded)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.collapse() }
        }
    }

    func collapse() {
        guard isExpanded else { return }
        autoCollapseTask?.cancel()
        isExpanded = false
        query = ""
        onResize?(Self.collapsed)
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }

    func send() {
        guard !query.isEmpty, phase != .thinking else { return }
        let q = query; query = ""; phase = .thinking
        autoCollapseTask?.cancel()
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
                phase = .done
                if let secs = s.autoCollapse.seconds {
                    autoCollapseTask = Task {
                        try? await Task.sleep(for: .seconds(secs))
                        if !Task.isCancelled { collapse() }
                    }
                }
            } catch {
                messages.append((q: q, r: error.localizedDescription, tokens: 0))
                phase = .error(error.localizedDescription)
            }
        }
    }
}
