import SwiftUI
import ServiceManagement

// MARK: - Root

struct SettingsView: View {
    @EnvironmentObject var s: SettingsStore
    @StateObject private var usage = UsageStore.shared
    @State private var nav: Nav = .widgets

    enum Nav: String, CaseIterable, Identifiable {
        case widgets  = "Widgets"
        case apikeys  = "API-Keys"
        case claude   = "Claude"
        case general  = "Allgemein"
        case usage    = "Nutzung"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .widgets: return "square.grid.2x2.fill"
            case .apikeys: return "key.fill"
            case .claude:  return "brain"
            case .general: return "gearshape.fill"
            case .usage:   return "chart.bar.fill"
            }
        }
        var color: Color {
            switch self {
            case .widgets: return .blue
            case .apikeys: return .yellow
            case .claude:  return .purple
            case .general: return .gray
            case .usage:   return .green
            }
        }
        var subtitle: String {
            switch self {
            case .widgets: return "Ein- / ausschalten"
            case .apikeys: return "Schlüssel verwalten"
            case .claude:  return "Modell & Parameter"
            case .general: return "App-Verhalten"
            case .usage:   return "Statistiken & Limits"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(nav: $nav)
            Divider()
            ScrollView {
                Group {
                    switch nav {
                    case .widgets: WidgetsSection(s: s)
                    case .apikeys: APIKeysSection(s: s)
                    case .claude:  ClaudeSection(s: s)
                    case .general: GeneralSection(s: s)
                    case .usage:   UsageSection(usage: usage)
                    }
                }
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 740, height: 520)
    }
}

// MARK: - Sidebar

struct SettingsSidebar: View {
    @Binding var nav: SettingsView.Nav

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(LinearGradient(colors: [.blue, .purple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42)
                    Image(systemName: "rectangle.topthird.inset.filled")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Island").font(.system(size: 14, weight: .bold))
                    Text("v1.1.0").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 16)

            Text("EINSTELLUNGEN")
                .font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.bottom, 8)

            ForEach(SettingsView.Nav.allCases) { item in
                SideNavRow(item: item, isSelected: nav == item)
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { nav = item } }
            }

            Spacer()
            Divider().padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 7) {
                SideLink(icon: "arrow.up.right.square", label: "console.anthropic.com",
                         url: "https://console.anthropic.com/")
                SideLink(icon: "doc.text",              label: "API-Dokumentation",
                         url: "https://docs.anthropic.com/")
                SideLink(icon: "ant",                   label: "anthropic.com/pricing",
                         url: "https://anthropic.com/pricing")
            }
            .padding(.horizontal, 18).padding(.bottom, 18)
        }
        .frame(width: 200)
        .background(SidebarMaterial())
    }
}

struct SideNavRow: View {
    let item: SettingsView.Nav; let isSelected: Bool
    @State private var hovered = false
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? item.color : item.color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: item.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : item.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.rawValue).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text(item.subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 9)
            .fill(isSelected ? item.color.opacity(0.1) : (hovered ? Color.secondary.opacity(0.07) : .clear)))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.1), value: hovered)
    }
}

struct SideLink: View {
    let icon: String; let label: String; let url: String
    @State private var hovered = false
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(.secondary)
                Text(label).font(.system(size: 10)).foregroundStyle(hovered ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain).onHover { hovered = $0 }
    }
}

struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView(); v.material = .sidebar
        v.blendingMode = .behindWindow; v.state = .active; return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Card

struct SCard<Content: View>: View {
    let icon: String; let color: Color; let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(color.gradient).frame(width: 26, height: 26)
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                }
                Text(title).font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            Divider()
            content().padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.primary.opacity(0.07), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}

struct SectionHead: View {
    let title: String; let subtitle: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 22, weight: .bold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }.padding(.bottom, 6)
    }
}

// MARK: - Widgets Section

struct WidgetsSection: View {
    @ObservedObject var s: SettingsStore

    private let widgetInfo: [(kind: String, icon: String, color: Color, name: String, desc: String, note: String?)] = [
        ("claude",  "brain",                    .blue,   "Claude AI",  "KI-Assistent von Anthropic. Beantwortet Fragen, schreibt Texte.", "Benötigt Claude API-Key"),
        ("music",   "music.note",               .pink,   "Musik",      "Zeigt aktuell spielende Musik aus Apple Music oder Spotify.", "Benötigt Automationserlaubnis"),
        ("timer",   "timer",                    .orange, "Timer",      "Pomodoro- und Countdown-Timer direkt in der Notch.", nil),
        ("system",  "cpu",                      .green,  "System",     "CPU-Auslastung, RAM-Verbrauch und Akkustand in Echtzeit.", nil),
        ("weather", "cloud.sun.fill",           .cyan,   "Wetter",     "Aktuelle Temperatur und Wetterlage via IP-Standort.",  "Benötigt Internetverbindung"),
    ]

    var body: some View {
        VStack(spacing: 14) {
            SectionHead(title: "Widgets", subtitle: "Aktiviere nur was du brauchst")

            ForEach(widgetInfo, id: \.kind) { w in
                WidgetToggleCard(
                    kind: w.kind, icon: w.icon, color: w.color,
                    name: w.name, desc: w.desc, note: w.note, s: s
                )
            }
        }
    }
}

struct WidgetToggleCard: View {
    let kind: String; let icon: String; let color: Color
    let name: String; let desc: String; let note: String?
    @ObservedObject var s: SettingsStore
    @State private var expanded = false

    var isOn: Bool { s.isWidgetEnabled(kind) }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? color.gradient : LinearGradient(colors: [.secondary.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isOn ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(name).font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isOn ? .primary : .secondary)
                        if let note {
                            Text(note)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    Text(desc).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { s.setWidget(kind, enabled: $0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(color)
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture { if isOn { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } }

            // Per-widget settings (expandable)
            if expanded && isOn {
                Divider()
                WidgetSubSettings(kind: kind, s: s)
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13)
            .stroke(isOn ? color.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: isOn ? 1.5 : 1))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

struct WidgetSubSettings: View {
    let kind: String; @ObservedObject var s: SettingsStore
    var body: some View {
        switch kind {
        case "timer":
            VStack(spacing: 10) {
                HStack {
                    Text("Standard-Dauer").font(.callout)
                    Spacer()
                    Text("\(Int(s.timerDefaultMinutes)) min")
                        .font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
                }
                Slider(value: $s.timerDefaultMinutes, in: 5...60, step: 5).tint(.orange)
                Toggle("Ton bei Ende", isOn: $s.timerSound)
            }
        case "system":
            VStack(spacing: 10) {
                HStack {
                    Text("Aktualisierung").font(.callout)
                    Spacer()
                    Picker("", selection: $s.systemRefreshInterval) {
                        Text("5 s").tag(5.0)
                        Text("10 s").tag(10.0)
                        Text("30 s").tag(30.0)
                    }
                    .pickerStyle(.menu).frame(width: 80)
                }
            }
        case "music":
            Toggle("Steuerknöpfe anzeigen", isOn: $s.musicShowControls)
        case "weather":
            HStack(spacing: 8) {
                Image(systemName: "location.fill").foregroundStyle(.cyan).font(.caption)
                TextField("Stadt (leer = automatisch via IP)", text: $s.weatherCity)
                    .textFieldStyle(.roundedBorder).font(.callout)
            }
        case "claude":
            HStack(spacing: 6) {
                Image(systemName: "info.circle").foregroundStyle(.blue).font(.caption)
                Text("Claude-Einstellungen unter \"Claude\" konfigurieren")
                    .font(.caption).foregroundStyle(.secondary)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - API Keys Section

struct APIKeysSection: View {
    @ObservedObject var s: SettingsStore

    var body: some View {
        VStack(spacing: 14) {
            SectionHead(title: "API-Keys", subtitle: "Alle Schlüssel werden nur lokal gespeichert")

            APIKeyCard(
                icon: "brain", color: .purple, service: "Claude (Anthropic)",
                subtitle: "Für den Claude AI-Widget",
                placeholder: "sk-ant-api03-…",
                hint: "Holen → console.anthropic.com",
                hintURL: "https://console.anthropic.com/",
                key: $s.claudeApiKey,
                validator: { k in k.hasPrefix("sk-ant") ? .valid : (k.isEmpty ? .empty : .invalid) }
            )

            APIKeyCard(
                icon: "sparkles", color: .green, service: "OpenAI (optional)",
                subtitle: "Für zukünftige ChatGPT-Integration",
                placeholder: "sk-…",
                hint: "Holen → platform.openai.com",
                hintURL: "https://platform.openai.com/api-keys",
                key: $s.openAiApiKey,
                validator: { k in k.hasPrefix("sk-") ? .valid : (k.isEmpty ? .empty : .invalid) }
            )

            // Info card
            SCard(icon: "lock.shield.fill", color: .gray, title: "Sicherheit") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "internaldrive", text: "Alle Keys werden lokal in UserDefaults gespeichert")
                    InfoRow(icon: "xmark.icloud", text: "Keine Übertragung an Dritte — nur direkte API-Aufrufe")
                    InfoRow(icon: "eye.slash", text: "Keys werden maskiert angezeigt")
                }
            }
        }
    }
}

enum KeyStatus { case empty, valid, invalid }

struct APIKeyCard: View {
    let icon: String; let color: Color; let service: String; let subtitle: String
    let placeholder: String; let hint: String; let hintURL: String
    @Binding var key: String
    let validator: (String) -> KeyStatus

    @State private var showKey = false
    @State private var testStatus: TestState = .idle
    enum TestState: Equatable { case idle, testing, ok, fail(String) }

    var status: KeyStatus { validator(key) }

    var body: some View {
        SCard(icon: icon, color: color, title: service) {
            VStack(alignment: .leading, spacing: 12) {
                // Subtitle
                Text(subtitle).font(.caption).foregroundStyle(.secondary)

                // Key field
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if showKey {
                            TextField(placeholder, text: $key)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .autocorrectionDisabled()
                        } else {
                            SecureField(placeholder, text: $key)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    // Show/hide
                    Button { showKey.toggle() } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary).frame(width: 28, height: 28)
                    }.buttonStyle(.bordered)

                    // Status badge
                    switch status {
                    case .empty:   EmptyView()
                    case .valid:
                        Label("Gültig", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold()).foregroundStyle(.green)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.green.opacity(0.1)).clipShape(Capsule())
                    case .invalid:
                        Label("Ungültig", systemImage: "xmark.circle.fill")
                            .font(.caption.bold()).foregroundStyle(.red)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.red.opacity(0.1)).clipShape(Capsule())
                    }
                }

                // Bottom row
                HStack {
                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary)
                    Text("Nur lokal gespeichert").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if !key.isEmpty {
                        Button { copyKey() } label: {
                            Label("Kopieren", systemImage: "doc.on.doc").font(.caption)
                        }.buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                    Link(hint, destination: URL(string: hintURL)!).font(.caption.bold())
                }
            }
        }
    }

    private func copyKey() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(key, forType: .string) }
}

struct InfoRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary).frame(width: 16)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Claude Section

struct ClaudeSection: View {
    @ObservedObject var s: SettingsStore
    var body: some View {
        VStack(spacing: 14) {
            SectionHead(title: "Claude", subtitle: "Modell und Antwortverhalten konfigurieren")

            // Model picker cards
            SCard(icon: "brain", color: .purple, title: "Modell wählen") {
                HStack(spacing: 10) {
                    ForEach(SettingsStore.Model.allCases) { m in
                        ModelPill(model: m, isSelected: s.selectedModel == m)
                            .onTapGesture { withAnimation(.spring(response: 0.25)) { s.selectedModel = m } }
                    }
                }
            }

            SCard(icon: "slider.horizontal.3", color: .indigo, title: "Parameter") {
                VStack(spacing: 16) {
                    SliderRow(label: "Max. Tokens", value: Binding(
                        get: { Double(s.maxTokens) }, set: { s.maxTokens = Int($0) }
                    ), range: 256...4096, step: 256,
                       display: "\(s.maxTokens)",
                       leftNote: "256 – kurz", rightNote: "4096 – lang", tint: .indigo)

                    Divider()

                    SliderRow(label: "Temperatur", value: $s.temperature,
                       range: 0...1, step: 0.05,
                       display: String(format: "%.2f", s.temperature),
                       leftNote: "Präzise", rightNote: "Kreativ", tint: .orange)
                }
            }

            SCard(icon: "text.bubble", color: .cyan, title: "System-Prompt") {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $s.systemPrompt)
                        .font(.system(size: 13)).frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    Text("Definiert Claudes Persönlichkeit. Leer lassen für Standard.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct ModelPill: View {
    let model: SettingsStore.Model; let isSelected: Bool
    @State private var hovered = false
    var body: some View {
        VStack(spacing: 8) {
            Text(model.emoji).font(.title2)
            Text(model.label).font(.system(size: 11, weight: .semibold))
            Text(model.sublabel).font(.system(size: 10)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if isSelected {
                Text("Aktiv").font(.system(size: 9, weight: .bold)).foregroundStyle(.purple)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(.purple.opacity(0.12)).clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(isSelected ? .purple.opacity(0.08) : (hovered ? Color.secondary.opacity(0.06) : .clear))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.purple.opacity(0.35) : Color.secondary.opacity(0.12),
                    lineWidth: isSelected ? 1.5 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.1), value: hovered)
    }
}

struct SliderRow: View {
    let label: String; @Binding var value: Double
    let range: ClosedRange<Double>; let step: Double
    let display: String; let leftNote: String; let rightNote: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.callout); Spacer()
                Text(display).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step).tint(tint)
            HStack {
                Text(leftNote).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(rightNote).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - General Section

struct GeneralSection: View {
    @ObservedObject var s: SettingsStore
    var body: some View {
        VStack(spacing: 14) {
            SectionHead(title: "Allgemein", subtitle: "App-Verhalten anpassen")

            SCard(icon: "rectangle.topthird.inset.filled", color: .orange, title: "Island-Verhalten") {
                VStack(spacing: 0) {
                    ToggleRow(label: "Token-Anzeige", subtitle: "Zeigt Verbrauch in der Notch", value: $s.showUsageInIsland)
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Schließen").font(.callout)
                            Text("Island schließt sich automatisch").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $s.autoCollapse) {
                            ForEach(SettingsStore.AutoCollapse.allCases) { c in Text(c.label).tag(c) }
                        }.pickerStyle(.menu).frame(width: 80)
                    }
                    .padding(.vertical, 10)
                }
            }

            SCard(icon: "power", color: .pink, title: "Systemstart") {
                ToggleRow(
                    label: "Bei Anmeldung starten",
                    subtitle: "Mac Island startet automatisch mit macOS",
                    value: $s.startAtLogin,
                    onChange: { val in
                        if #available(macOS 13.0, *) {
                            try? val ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        }
                    }
                )
            }

            SCard(icon: "keyboard", color: .gray, title: "Bedienung") {
                VStack(spacing: 0) {
                    ShortRow(action: "Island öffnen / schließen", key: "Klick auf Island")
                    Divider()
                    ShortRow(action: "Widget wechseln", key: "Punkte in der Pill")
                    Divider()
                    ShortRow(action: "Frage senden (Claude)", key: "↵ Return")
                    Divider()
                    ShortRow(action: "Einstellungen", key: "⌘,  oder Menüleiste")
                }
            }
        }
    }
}

struct ToggleRow: View {
    let label: String; let subtitle: String; @Binding var value: Bool
    var onChange: ((Bool) -> Void)? = nil
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.callout)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $value).labelsHidden()
                .onChange(of: value) { onChange?($0) }
        }
        .padding(.vertical, 10)
    }
}

struct ShortRow: View {
    let action: String; let key: String
    var body: some View {
        HStack {
            Text(action).font(.callout); Spacer()
            Text(key).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Usage Section

struct UsageSection: View {
    @ObservedObject var usage: UsageStore
    var body: some View {
        VStack(spacing: 14) {
            SectionHead(title: "Nutzung & Limits", subtitle: "Token-Verbrauch und API Rate Limits")

            HStack(spacing: 12) {
                BigStat(value: "\(usage.sessionTotal)", label: "Session", icon: "bolt.fill", color: .blue)
                BigStat(value: "\(usage.todayTokens)",  label: "Heute",   icon: "calendar",  color: .purple)
                BigStat(value: "\(usage.sessionRequests)", label: "Anfragen", icon: "arrow.up.arrow.down", color: .orange)
            }

            SCard(icon: "chart.bar.fill", color: .green, title: "Tokens (Session)") {
                VStack(spacing: 0) {
                    StatRow(label: "Input", value: "\(usage.sessionInputTokens)")
                    Divider()
                    StatRow(label: "Output", value: "\(usage.sessionOutputTokens)")
                    Divider()
                    StatRow(label: "Gesamt", value: "\(usage.sessionTotal)")
                    Divider()
                    HStack {
                        Button("Session zurücksetzen") { usage.resetSession() }
                            .foregroundStyle(.red).font(.callout).buttonStyle(.plain)
                        Spacer()
                    }.padding(.vertical, 8)
                }
            }

            SCard(icon: "gauge.high", color: .red, title: "Rate Limits (letzte Antwort)") {
                if usage.rateLimit.requestsLimit == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle").foregroundStyle(.secondary)
                        Text("Erscheint nach der ersten Claude-Anfrage")
                            .font(.callout).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                } else {
                    VStack(spacing: 12) {
                        if let lim = usage.rateLimit.requestsLimit, let rem = usage.rateLimit.requestsRemaining {
                            LimitRow(label: "Anfragen / min", rem: rem, lim: lim, reset: usage.rateLimit.requestsReset)
                        }
                        if let lim = usage.rateLimit.tokensLimit, let rem = usage.rateLimit.tokensRemaining {
                            LimitRow(label: "Tokens / min",   rem: rem, lim: lim, reset: usage.rateLimit.tokensReset)
                        }
                    }
                }
            }
        }
    }
}

struct BigStat: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.13), lineWidth: 1))
    }
}

struct StatRow: View {
    let label: String; let value: String
    var body: some View {
        HStack { Text(label).font(.callout); Spacer()
            Text(value).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
        }.padding(.vertical, 8)
    }
}

struct LimitRow: View {
    let label: String; let rem: Int; let lim: Int; let reset: String?
    var pct: Double { lim > 0 ? Double(rem) / Double(lim) : 0 }
    var tint: Color { pct > 0.3 ? .green : pct > 0.1 ? .yellow : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text(label).font(.callout); Spacer()
                Text("\(rem) / \(lim)").font(.system(size: 12, design: .monospaced)).foregroundStyle(tint)
            }
            ProgressView(value: pct).tint(tint)
            if let r = reset { Text("Reset: \(r)").font(.caption2).foregroundStyle(.tertiary) }
        }
    }
}
