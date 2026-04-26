import SwiftUI
import ServiceManagement

// MARK: - Root

struct SettingsView: View {
    @EnvironmentObject var s: SettingsStore
    @StateObject private var usage = UsageStore.shared
    @State private var nav: NavItem = .api

    enum NavItem: String, CaseIterable, Identifiable {
        case api    = "API"
        case model  = "Modell"
        case island = "Island"
        case usage  = "Nutzung"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .api:    return "key.fill"
            case .model:  return "brain"
            case .island: return "rectangle.topthird.inset.filled"
            case .usage:  return "chart.bar.fill"
            }
        }
        var color: Color {
            switch self {
            case .api:    return .blue
            case .model:  return .purple
            case .island: return .orange
            case .usage:  return .green
            }
        }
        var subtitle: String {
            switch self {
            case .api:    return "Schlüssel & Verbindung"
            case .model:  return "KI-Modell & Parameter"
            case .island: return "Aussehen & Verhalten"
            case .usage:  return "Statistiken & Limits"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(nav: $nav)
            Divider()
            contentPane
        }
        .frame(width: 720, height: 500)
    }

    @ViewBuilder
    private var contentPane: some View {
        ScrollView {
            Group {
                switch nav {
                case .api:    APIContent(s: s)
                case .model:  ModelContent(s: s)
                case .island: IslandContent(s: s)
                case .usage:  UsageContent(usage: usage)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @Binding var nav: SettingsView.NavItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    Image(systemName: "brain")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Claude Island")
                        .font(.system(size: 13, weight: .bold))
                    Text("v1.0.0 · macOS")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Text("EINSTELLUNGEN")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

            ForEach(SettingsView.NavItem.allCases) { item in
                NavRow(item: item, isSelected: nav == item)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) { nav = item }
                    }
            }

            Spacer()
            Divider().padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                FooterLink(icon: "arrow.up.right.square", label: "console.anthropic.com",
                           url: "https://console.anthropic.com/")
                FooterLink(icon: "doc.text",              label: "API-Dokumentation",
                           url: "https://docs.anthropic.com/")
                FooterLink(icon: "ant",                   label: "Anthropic Pricing",
                           url: "https://anthropic.com/pricing")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 195)
        .background(SidebarMaterial())
    }
}

struct NavRow: View {
    let item: SettingsView.NavItem
    let isSelected: Bool
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? item.color : item.color.opacity(0.13))
                    .frame(width: 28, height: 28)
                Image(systemName: item.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : item.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text(item.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isSelected ? item.color.opacity(0.12) : (hovered ? Color.secondary.opacity(0.08) : .clear))
        )
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.12), value: hovered)
    }
}

struct FooterLink: View {
    let icon: String; let label: String; let url: String
    @State private var hovered = false
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(.secondary)
                Text(label).font(.system(size: 10)).foregroundStyle(hovered ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.1), value: hovered)
    }
}

struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Card

struct Card<Content: View>: View {
    let icon: String; let color: Color; let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.gradient)
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title).font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            Divider().padding(.horizontal, 1)

            content().padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.primary.opacity(0.07), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}

// MARK: - API Section

struct APIContent: View {
    @ObservedObject var s: SettingsStore
    @State private var showKey = false
    @State private var testStatus: TestStatus = .idle
    enum TestStatus { case idle, testing, ok, fail(String) }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "API", subtitle: "Verbinde Claude Island mit deinem Anthropic-Account")

            Card(icon: "key.fill", color: .blue, title: "API-Key") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Group {
                            if showKey {
                                TextField("sk-ant-api03-…", text: $s.apiKey)
                            } else {
                                SecureField("sk-ant-api03-…", text: $s.apiKey)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.bordered)

                        // Validity indicator
                        if !s.apiKey.isEmpty {
                            Image(systemName: s.apiKey.hasPrefix("sk-ant") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(s.apiKey.hasPrefix("sk-ant") ? .green : .red)
                        }
                    }

                    HStack {
                        Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary)
                        Text("Wird nur lokal gespeichert · niemals übertragen")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Link("Holen →", destination: URL(string: "https://console.anthropic.com/")!)
                            .font(.caption.bold())
                    }
                }
            }

            Card(icon: "wifi", color: .teal, title: "Verbindung testen") {
                HStack(spacing: 14) {
                    Button("Verbindung testen") {
                        guard !s.apiKey.isEmpty else { testStatus = .fail("Kein API-Key"); return }
                        testStatus = .testing
                        Task {
                            do {
                                _ = try await ClaudeAPIService.shared.send(
                                    query: "Say 'ok'", model: s.selectedModel.rawValue,
                                    maxTokens: 10, temperature: 0, system: nil, apiKey: s.apiKey)
                                testStatus = .ok
                            } catch {
                                testStatus = .fail(error.localizedDescription)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(s.apiKey.isEmpty || testStatus == .testing)

                    switch testStatus {
                    case .idle:         EmptyView()
                    case .testing:      ProgressView().scaleEffect(0.8)
                    case .ok:
                        Label("Verbunden", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.callout.bold())
                    case .fail(let m):
                        Label(m, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red).font(.callout)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Model Section

struct ModelContent: View {
    @ObservedObject var s: SettingsStore

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Modell", subtitle: "Wähle das Claude-Modell und stelle Parameter ein")

            Card(icon: "brain", color: .purple, title: "Claude-Modell") {
                HStack(spacing: 10) {
                    ForEach(SettingsStore.Model.allCases) { m in
                        ModelCard(model: m, isSelected: s.selectedModel == m)
                            .onTapGesture { withAnimation(.spring(response: 0.25)) { s.selectedModel = m } }
                    }
                }
            }

            Card(icon: "slider.horizontal.3", color: .indigo, title: "Parameter") {
                VStack(spacing: 16) {
                    // Max Tokens
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Max. Tokens").font(.callout)
                            Spacer()
                            Text("\(s.maxTokens)")
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                        Slider(value: Binding(get: { Double(s.maxTokens) }, set: { s.maxTokens = Int($0) }),
                               in: 256...4096, step: 256)
                            .tint(.indigo)
                        HStack {
                            Text("256 – kurz").font(.caption2).foregroundStyle(.tertiary)
                            Spacer()
                            Text("4096 – ausführlich").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }

                    Divider()

                    // Temperature
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Temperatur").font(.callout)
                            Spacer()
                            Text(String(format: "%.2f", s.temperature))
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                        Slider(value: $s.temperature, in: 0...1, step: 0.05).tint(.orange)
                        HStack {
                            Text("0.0 – präzise").font(.caption2).foregroundStyle(.tertiary)
                            Spacer()
                            Text("1.0 – kreativ").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Card(icon: "text.bubble", color: .cyan, title: "System-Prompt") {
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $s.systemPrompt)
                        .font(.system(size: 13))
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    Text("Definiert Claudes Persönlichkeit und Antwortformat.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct ModelCard: View {
    let model: SettingsStore.Model
    let isSelected: Bool
    @State private var hovered = false

    var emoji: String {
        switch model {
        case .haiku:  return "⚡"
        case .sonnet: return "⚖️"
        case .opus:   return "🏆"
        }
    }
    var name: String {
        switch model {
        case .haiku:  return "Haiku 4.5"
        case .sonnet: return "Sonnet 4.6"
        case .opus:   return "Opus 4.7"
        }
    }
    var desc: String {
        switch model {
        case .haiku:  return "Schnell\n& günstig"
        case .sonnet: return "Ausge-\nwogen"
        case .opus:   return "Leistungs-\nstark"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.title2)
            Text(name).font(.system(size: 11, weight: .semibold))
            Text(desc)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if isSelected {
                Label("Aktiv", systemImage: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.purple.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? Color.purple.opacity(0.08) : (hovered ? Color.secondary.opacity(0.06) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.purple.opacity(0.4) : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.12), value: hovered)
    }
}

// MARK: - Island Section

struct IslandContent: View {
    @ObservedObject var s: SettingsStore

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Island", subtitle: "Passe das Verhalten des schwebenden Widgets an")

            Card(icon: "rectangle.topthird.inset.filled", color: .orange, title: "Verhalten") {
                VStack(spacing: 0) {
                    SettingsRow {
                        Text("Auto-Schließen nach")
                        Spacer()
                        Picker("", selection: $s.autoCollapse) {
                            ForEach(SettingsStore.AutoCollapse.allCases) { c in
                                Text(c.label).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    Divider()
                    SettingsRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Token-Anzeige")
                            Text("Zeigt Verbrauch im Island an")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $s.showUsageInIsland).labelsHidden()
                    }
                }
            }

            Card(icon: "power", color: .pink, title: "Systemstart") {
                VStack(spacing: 0) {
                    SettingsRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bei Anmeldung starten")
                            Text("Claude Island startet automatisch mit macOS")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $s.startAtLogin)
                            .labelsHidden()
                            .onChange(of: s.startAtLogin) { val in
                                if #available(macOS 13.0, *) {
                                    try? val ? SMAppService.mainApp.register()
                                             : SMAppService.mainApp.unregister()
                                }
                            }
                    }
                }
            }

            Card(icon: "keyboard", color: .gray, title: "Bedienung") {
                VStack(spacing: 0) {
                    ShortcutRow(action: "Island öffnen / schließen", key: "Klick auf Island")
                    Divider()
                    ShortcutRow(action: "Frage senden",              key: "↵ Return")
                    Divider()
                    ShortcutRow(action: "Einstellungen",             key: "⌘,  oder Menüleiste")
                }
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        HStack(spacing: 12) { content() }
            .padding(.vertical, 10)
    }
}

struct ShortcutRow: View {
    let action: String; let key: String
    var body: some View {
        HStack {
            Text(action).font(.callout)
            Spacer()
            Text(key)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Usage Section

struct UsageContent: View {
    @ObservedObject var usage: UsageStore

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Nutzung & Limits", subtitle: "Token-Verbrauch und API Rate Limits in Echtzeit")

            // Stats row
            HStack(spacing: 12) {
                StatCard(value: "\(usage.sessionTotal)", label: "Session Tokens",  icon: "bolt.fill",       color: .blue)
                StatCard(value: "\(usage.todayTokens)",  label: "Heute gesamt",    icon: "calendar",        color: .purple)
                StatCard(value: "\(usage.sessionRequests)", label: "Anfragen",     icon: "arrow.up.arrow.down", color: .orange)
            }

            Card(icon: "chart.bar.fill", color: .green, title: "Diese Session") {
                VStack(spacing: 0) {
                    UsageStat(label: "Input-Tokens",  value: "\(usage.sessionInputTokens)")
                    Divider()
                    UsageStat(label: "Output-Tokens", value: "\(usage.sessionOutputTokens)")
                    Divider()
                    UsageStat(label: "Gesamt",        value: "\(usage.sessionTotal)")
                    Divider()
                    HStack {
                        Button("Session zurücksetzen") { usage.resetSession() }
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            Card(icon: "gauge.high", color: .red, title: "API Rate Limits (Echtzeit)") {
                if usage.rateLimit.requestsLimit == nil {
                    HStack {
                        Image(systemName: "info.circle").foregroundStyle(.secondary)
                        Text("Erscheint nach der ersten API-Anfrage")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 14) {
                        if let lim = usage.rateLimit.requestsLimit,
                           let rem = usage.rateLimit.requestsRemaining {
                            LimitBar(label: "Anfragen / Minute", remaining: rem, limit: lim,
                                     reset: usage.rateLimit.requestsReset)
                        }
                        if let lim = usage.rateLimit.tokensLimit,
                           let rem = usage.rateLimit.tokensRemaining {
                            LimitBar(label: "Tokens / Minute", remaining: rem, limit: lim,
                                     reset: usage.rateLimit.tokensReset)
                        }
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1))
    }
}

struct UsageStat: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.callout)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct LimitBar: View {
    let label: String; let remaining: Int; let limit: Int; let reset: String?
    var pct: Double { limit > 0 ? Double(remaining) / Double(limit) : 0 }
    var tint: Color { pct > 0.3 ? .green : pct > 0.1 ? .yellow : .red }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.callout)
                Spacer()
                Text("\(remaining) / \(limit)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(tint)
            }
            ProgressView(value: pct).tint(tint)
            if let r = reset {
                Text("Reset: \(r)").font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String; let subtitle: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 22, weight: .bold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}
