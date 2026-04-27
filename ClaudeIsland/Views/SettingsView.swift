import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var s: SettingsStore
    @StateObject private var usage = UsageStore.shared
    @State private var nav: Nav = .api

    enum Nav: String, CaseIterable, Identifiable {
        case api = "API-Key", model = "Modell", behavior = "Verhalten", usage = "Nutzung"
        var id: String { rawValue }
        var icon: String {
            switch self { case .api: return "key.fill"; case .model: return "brain"; case .behavior: return "gearshape.fill"; case .usage: return "chart.bar.fill" }
        }
        var color: Color {
            switch self { case .api: return .blue; case .model: return .purple; case .behavior: return .orange; case .usage: return .green }
        }
        var subtitle: String {
            switch self { case .api: return "Schlüssel & Verbindung"; case .model: return "Modell & Parameter"; case .behavior: return "Island & Darstellung"; case .usage: return "Statistiken & Limits" }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            ScrollView {
                content.padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 680, height: 480)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "brain")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Claude Island").font(.system(size: 13, weight: .bold))
                    Text("v1.3.0 · macOS").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 18)

            Text("EINSTELLUNGEN")
                .font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.bottom, 8)

            ForEach(Nav.allCases) { item in
                SideRow(item: item, isSelected: nav == item)
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { nav = item } }
            }

            Spacer()
            Divider().padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 7) {
                FootLink(icon: "arrow.up.right.square", label: "console.anthropic.com",
                         url: "https://console.anthropic.com/")
                FootLink(icon: "doc.text", label: "API-Dokumentation",
                         url: "https://docs.anthropic.com/")
            }
            .padding(.horizontal, 18).padding(.bottom, 18)
        }
        .frame(width: 195)
        .background(SidebarMaterial())
    }

    @ViewBuilder
    private var content: some View {
        switch nav {
        case .api:      APIView(s: s)
        case .model:    ModelView(s: s)
        case .behavior: BehaviorView(s: s)
        case .usage:    UsageView(usage: usage)
        }
    }
}

// MARK: - Sidebar helpers

struct SideRow: View {
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
        .padding(.horizontal, 8).contentShape(Rectangle())
        .onHover { hovered = $0 }.animation(.easeOut(duration: 0.1), value: hovered)
    }
}

struct FootLink: View {
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

struct Card<Content: View>: View {
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
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct SecHead: View {
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

// MARK: - API

struct APIView: View {
    @ObservedObject var s: SettingsStore
    @State private var showKey = false
    @State private var testing = false
    @State private var testOK: Bool? = nil

    var keyValid: Bool { s.apiKey.hasPrefix("sk-ant") }

    var body: some View {
        VStack(spacing: 14) {
            SecHead(title: "API-Key", subtitle: "Dein Anthropic-Schlüssel für Claude")

            Card(icon: "key.fill", color: .blue, title: "Claude API-Key") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Group {
                            if showKey {
                                TextField("sk-ant-api03-…", text: $s.apiKey)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-ant-api03-…", text: $s.apiKey)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye").frame(width: 26, height: 26)
                        }.buttonStyle(.bordered)

                        if !s.apiKey.isEmpty {
                            Image(systemName: keyValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(keyValid ? .green : .red)
                        }
                    }

                    HStack {
                        Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary)
                        Text("Nur lokal gespeichert — wird nie weitergegeben")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Link("Holen →", destination: URL(string: "https://console.anthropic.com/")!)
                            .font(.caption.bold())
                    }
                }
            }

            Card(icon: "wifi", color: .teal, title: "Verbindung testen") {
                HStack(spacing: 14) {
                    Button(testing ? "Teste…" : "Verbindung testen") {
                        testing = true; testOK = nil
                        Task {
                            do {
                                _ = try await ClaudeAPIService.shared.send(
                                    query: "Say ok", model: s.selectedModel.rawValue,
                                    maxTokens: 10, temperature: 0, system: nil, apiKey: s.apiKey)
                                testOK = true
                            } catch { testOK = false }
                            testing = false
                        }
                    }
                    .buttonStyle(.borderedProminent).disabled(s.apiKey.isEmpty || testing)

                    if testing { ProgressView().scaleEffect(0.8) }
                    else if let ok = testOK {
                        Label(ok ? "Verbunden" : "Fehler",
                              systemImage: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(ok ? .green : .red).font(.callout.bold())
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Model

struct ModelView: View {
    @ObservedObject var s: SettingsStore
    var body: some View {
        VStack(spacing: 14) {
            SecHead(title: "Modell", subtitle: "Wähle Claude-Modell und stelle Parameter ein")

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
                    SliderRow(label: "Max. Tokens",
                              value: Binding(get: { Double(s.maxTokens) }, set: { s.maxTokens = Int($0) }),
                              range: 256...4096, step: 256,
                              display: "\(s.maxTokens)",
                              left: "256 – kurz", right: "4096 – lang", tint: .indigo)
                    Divider()
                    SliderRow(label: "Temperatur", value: $s.temperature,
                              range: 0...1, step: 0.05,
                              display: String(format: "%.2f", s.temperature),
                              left: "Präzise", right: "Kreativ", tint: .orange)
                }
            }

            Card(icon: "text.bubble", color: .cyan, title: "System-Prompt") {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $s.systemPrompt)
                        .font(.system(size: 13)).frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    Text("Definiert Claudes Verhalten. Leer lassen für Standard.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct ModelCard: View {
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
        .onHover { hovered = $0 }.animation(.easeOut(duration: 0.1), value: hovered)
    }
}

struct SliderRow: View {
    let label: String; @Binding var value: Double
    let range: ClosedRange<Double>; let step: Double
    let display: String; let left: String; let right: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.callout); Spacer()
                Text(display).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step).tint(tint)
            HStack {
                Text(left).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(right).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Behavior

struct BehaviorView: View {
    @ObservedObject var s: SettingsStore
    var body: some View {
        VStack(spacing: 14) {
            SecHead(title: "Verhalten", subtitle: "Island-Verhalten und App-Einstellungen")

            Card(icon: "rectangle.topthird.inset.filled", color: .orange, title: "Island") {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Token-Anzeige").font(.callout)
                            Text("Zeigt Verbrauch in der Pill").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $s.showUsageInIsland).labelsHidden()
                    }
                    .padding(.vertical, 10)
                    Divider()
                    HStack {
                        Text("Auto-Schließen").font(.callout)
                        Spacer()
                        Picker("", selection: $s.autoCollapse) {
                            ForEach(SettingsStore.AutoCollapse.allCases) { c in Text(c.label).tag(c) }
                        }.pickerStyle(.menu).frame(width: 80)
                    }
                    .padding(.vertical, 10)
                }
            }

            Card(icon: "power", color: .pink, title: "Systemstart") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bei Anmeldung starten").font(.callout)
                        Text("Mac Island öffnet sich automatisch").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $s.startAtLogin).labelsHidden()
                        .onChange(of: s.startAtLogin) { val in
                            if #available(macOS 13.0, *) {
                                try? val ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                            }
                        }
                }
                .padding(.vertical, 2)
            }

            Card(icon: "keyboard", color: .gray, title: "Bedienung") {
                VStack(spacing: 0) {
                    KbRow(action: "Island öffnen / schließen", key: "Klick")
                    Divider()
                    KbRow(action: "Frage senden", key: "↵ Return")
                    Divider()
                    KbRow(action: "Einstellungen", key: "⌘,")
                    Divider()
                    KbRow(action: "Beenden", key: "Menüleiste → Beenden")
                }
            }
        }
    }
}

struct KbRow: View {
    let action: String; let key: String
    var body: some View {
        HStack {
            Text(action).font(.callout); Spacer()
            Text(key).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 5))
        }.padding(.vertical, 8)
    }
}

// MARK: - Usage

struct UsageView: View {
    @ObservedObject var usage: UsageStore
    var body: some View {
        VStack(spacing: 14) {
            SecHead(title: "Nutzung & Limits", subtitle: "Token-Verbrauch und API Rate Limits")

            HStack(spacing: 12) {
                BigNum(value: "\(usage.sessionTotal)",    label: "Session",  icon: "bolt.fill",           color: .blue)
                BigNum(value: "\(usage.todayTokens)",     label: "Heute",    icon: "calendar",             color: .purple)
                BigNum(value: "\(usage.sessionRequests)", label: "Anfragen", icon: "arrow.up.arrow.down",  color: .orange)
            }

            Card(icon: "chart.bar.fill", color: .green, title: "Session") {
                VStack(spacing: 0) {
                    StatRow(label: "Input-Tokens",  value: "\(usage.sessionInputTokens)")
                    Divider()
                    StatRow(label: "Output-Tokens", value: "\(usage.sessionOutputTokens)")
                    Divider()
                    StatRow(label: "Gesamt",        value: "\(usage.sessionTotal)")
                    Divider()
                    HStack {
                        Button("Zurücksetzen") { usage.resetSession() }
                            .foregroundStyle(.red).buttonStyle(.plain)
                        Spacer()
                    }.padding(.vertical, 8)
                }
            }

            Card(icon: "gauge.high", color: .red, title: "API Rate Limits") {
                if usage.rateLimit.requestsLimit == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle").foregroundStyle(.secondary)
                        Text("Erscheint nach der ersten Anfrage").font(.callout).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                } else {
                    VStack(spacing: 12) {
                        if let lim = usage.rateLimit.requestsLimit, let rem = usage.rateLimit.requestsRemaining {
                            LimitBar(label: "Anfragen / min", rem: rem, lim: lim, reset: usage.rateLimit.requestsReset)
                        }
                        if let lim = usage.rateLimit.tokensLimit, let rem = usage.rateLimit.tokensRemaining {
                            LimitBar(label: "Tokens / min",   rem: rem, lim: lim, reset: usage.rateLimit.tokensReset)
                        }
                    }
                }
            }
        }
    }
}

struct BigNum: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(color.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
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

struct LimitBar: View {
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
