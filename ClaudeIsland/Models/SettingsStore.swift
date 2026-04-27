import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let ud = UserDefaults.standard

    @Published var apiKey: String       { didSet { save("apiKey", apiKey) } }
    @Published var selectedModel: Model { didSet { save("model", selectedModel.rawValue) } }
    @Published var maxTokens: Int       { didSet { save("maxTokens", maxTokens) } }
    @Published var temperature: Double  { didSet { save("temperature", temperature) } }
    @Published var systemPrompt: String { didSet { save("systemPrompt", systemPrompt) } }
    @Published var autoCollapse: AutoCollapse { didSet { save("autoCollapse", autoCollapse.rawValue) } }
    @Published var showUsageInIsland: Bool { didSet { save("showUsage", showUsageInIsland) } }
    @Published var startAtLogin: Bool   { didSet { save("startAtLogin", startAtLogin) } }

    enum Model: String, CaseIterable, Identifiable {
        case haiku  = "claude-haiku-4-5-20251001"
        case sonnet = "claude-sonnet-4-6"
        case opus   = "claude-opus-4-7"
        var id: String { rawValue }
        var label: String {
            switch self { case .haiku: return "Haiku 4.5"; case .sonnet: return "Sonnet 4.6"; case .opus: return "Opus 4.7" }
        }
        var sublabel: String {
            switch self { case .haiku: return "Schnell & günstig"; case .sonnet: return "Ausgewogen"; case .opus: return "Leistungsstark" }
        }
        var emoji: String {
            switch self { case .haiku: return "⚡"; case .sonnet: return "⚖️"; case .opus: return "🏆" }
        }
    }

    enum AutoCollapse: String, CaseIterable, Identifiable {
        case off = "off", sec5 = "5", sec10 = "10", sec30 = "30"
        var id: String { rawValue }
        var label: String {
            switch self { case .off: return "Aus"; case .sec5: return "5 s"; case .sec10: return "10 s"; case .sec30: return "30 s" }
        }
        var seconds: Double? { Double(rawValue) }
    }

    private init() {
        apiKey        = ud.string(forKey: "apiKey") ?? ""
        systemPrompt  = ud.string(forKey: "systemPrompt") ?? "Du bist ein hilfreicher Assistent. Antworte kurz und präzise."
        startAtLogin  = ud.bool(forKey: "startAtLogin")
        showUsageInIsland = ud.object(forKey: "showUsage") as? Bool ?? true
        maxTokens     = ud.object(forKey: "maxTokens") as? Int ?? 1024
        temperature   = ud.object(forKey: "temperature") as? Double ?? 0.7
        let mRaw = ud.string(forKey: "model") ?? Model.haiku.rawValue
        selectedModel = Model(rawValue: mRaw) ?? .haiku
        let aRaw = ud.string(forKey: "autoCollapse") ?? AutoCollapse.off.rawValue
        autoCollapse  = AutoCollapse(rawValue: aRaw) ?? .off
    }

    private func save(_ key: String, _ value: Any) { ud.set(value, forKey: key) }
}
