import SwiftUI

// MARK: - Root

struct IslandView: View {
    @ObservedObject var mgr: IslandManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(.black)
                .shadow(color: .black.opacity(0.55), radius: 14, y: 7)

            if mgr.isExpanded {
                ExpandedIsland(mgr: mgr)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                CollapsedIsland(mgr: mgr)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: mgr.isExpanded)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Collapsed

struct CollapsedIsland: View {
    @ObservedObject var mgr: IslandManager

    var active: IslandManager.WidgetKind { mgr.collapsedWidget }

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: active.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(active.color)
                .symbolEffect(.pulse, isActive: pulsing)

            // Context content
            Group {
                switch active {
                case .claude:  ClaudeCollapsed(m: mgr.claude)
                case .music:   MusicCollapsed(m: mgr.music)
                case .timer:   TimerCollapsed(m: mgr.timer)
                case .system:  SystemCollapsed(m: mgr.system)
                case .weather: WeatherCollapsed(m: mgr.weather)
                }
            }

            Spacer(minLength: 0)

            // Widget switcher dots
            HStack(spacing: 5) {
                ForEach(IslandManager.WidgetKind.allCases) { kind in
                    Circle()
                        .fill(mgr.activeWidget == kind ? kind.color : .white.opacity(0.18))
                        .frame(width: 5, height: 5)
                        .onTapGesture { mgr.expand(to: kind) }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { mgr.expand() }
    }

    private var pulsing: Bool {
        switch active {
        case .claude:  return mgr.claude.isThinking
        case .music:   return mgr.music.isPlaying
        case .timer:   return mgr.timer.isRunning
        default:       return false
        }
    }
}

// MARK: Collapsed widget snippets

struct ClaudeCollapsed: View {
    @ObservedObject var m: ClaudeWidgetModel
    var body: some View {
        if m.isThinking {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.6).tint(.blue)
                Text("Denkt…").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
            }
        } else if let last = m.messages.last {
            Text(last.r).lineLimit(1)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
        } else {
            Text("Claude AI").font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct MusicCollapsed: View {
    @ObservedObject var m: MusicWidgetModel
    var body: some View {
        if m.isPlaying {
            VStack(alignment: .leading, spacing: 1) {
                Text(m.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                Text(m.artist).font(.system(size: 10)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
            }
        } else {
            Text("Kein Titel").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
        }
    }
}

struct TimerCollapsed: View {
    @ObservedObject var m: TimerWidgetModel
    var body: some View {
        HStack(spacing: 8) {
            Text(m.formatted)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(m.isRunning ? .orange : .white.opacity(0.6))
            Text(m.mode.rawValue)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

struct SystemCollapsed: View {
    @ObservedObject var m: SystemWidgetModel
    var body: some View {
        HStack(spacing: 10) {
            Label(String(format: "%.0f%%", m.cpuPercent), systemImage: "cpu")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
            Label(String(format: "%.1fG", m.ramUsedGB), systemImage: "memorychip")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green.opacity(0.7))
            if m.batteryPercent >= 0 {
                Label("\(m.batteryPercent)%", systemImage: m.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(m.batteryPercent < 20 ? .red : .green.opacity(0.6))
            }
        }
    }
}

struct WeatherCollapsed: View {
    @ObservedObject var m: WeatherWidgetModel
    var body: some View {
        if m.isLoading && m.temperature.isEmpty {
            ProgressView().scaleEffect(0.6).tint(.cyan)
        } else {
            HStack(spacing: 6) {
                Image(systemName: m.icon).foregroundStyle(.cyan)
                Text(m.temperature).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                Text(m.city).font(.system(size: 11)).foregroundStyle(.white.opacity(0.45)).lineLimit(1)
            }
        }
    }
}

// MARK: - Expanded

struct ExpandedIsland: View {
    @ObservedObject var mgr: IslandManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: mgr.activeWidget.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mgr.activeWidget.color)
                Text(mgr.activeWidget.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button { mgr.collapse() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().background(.white.opacity(0.08))

            // Content
            Group {
                switch mgr.activeWidget {
                case .claude:  ClaudeExpandedView(m: mgr.claude, mgr: mgr)
                case .music:   MusicExpandedView(m: mgr.music)
                case .timer:   TimerExpandedView(m: mgr.timer)
                case .system:  SystemExpandedView(m: mgr.system)
                case .weather: WeatherExpandedView(m: mgr.weather)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Widget selector bar
            Divider().background(.white.opacity(0.06))
            HStack(spacing: 0) {
                ForEach(IslandManager.WidgetKind.allCases) { kind in
                    WidgetTab(kind: kind, isActive: mgr.activeWidget == kind)
                        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { mgr.activeWidget = kind } }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }
}

struct WidgetTab: View {
    let kind: IslandManager.WidgetKind
    let isActive: Bool
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? kind.color : .white.opacity(0.3))
            Text(kind.label)
                .font(.system(size: 9, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? kind.color.opacity(0.9) : .white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isActive ? kind.color.opacity(0.12) : (hovered ? .white.opacity(0.04) : .clear))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
    }
}

// MARK: - Claude expanded

struct ClaudeExpandedView: View {
    @ObservedObject var m: ClaudeWidgetModel
    @ObservedObject var mgr: IslandManager
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if m.messages.isEmpty {
                            Text("Stell Claude eine Frage…")
                                .font(.caption).foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity).padding(.top, 16)
                        }
                        ForEach(Array(m.messages.enumerated()), id: \.offset) { i, msg in
                            MsgBubble(query: msg.q, response: msg.r, tokens: msg.tokens).id(i)
                        }
                        if m.isThinking { ThinkingRow() }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                }
                .onChange(of: m.messages.count) { _ in
                    withAnimation { proxy.scrollTo(m.messages.count - 1) }
                }
            }

            Divider().background(.white.opacity(0.08))

            // Input
            HStack(spacing: 8) {
                TextField("Frage eingeben…", text: $m.query)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(.white).focused($focused).onSubmit { m.ask() }
                Button(action: m.ask) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(m.query.isEmpty ? .white.opacity(0.2) : .blue)
                }
                .buttonStyle(.plain).disabled(m.query.isEmpty || m.isThinking)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .onAppear { focused = true }
    }
}

struct MsgBubble: View {
    let query: String; let response: String; let tokens: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Spacer(minLength: 40)
                Text(query).font(.caption).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.blue.opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "brain").font(.caption2).foregroundStyle(.blue).padding(.top, 3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(response).font(.caption).foregroundStyle(.white.opacity(0.88))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                    if tokens > 0 {
                        Text("\(tokens) Tokens").font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.25)).padding(.leading, 4)
                    }
                }
            }
        }
    }
}

struct ThinkingRow: View {
    @State private var dots = ""
    let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 6) {
            ProgressView().scaleEffect(0.6).tint(.blue)
            Text("Denkt nach\(dots)").font(.caption).foregroundStyle(.white.opacity(0.35))
        }
        .onReceive(timer) { _ in dots = dots.count < 3 ? dots + "." : "" }
    }
}

// MARK: - Music expanded

struct MusicExpandedView: View {
    @ObservedObject var m: MusicWidgetModel
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: m.isPlaying ? "music.note" : "music.note.slash")
                .font(.system(size: 48)).foregroundStyle(.pink.opacity(0.8))

            VStack(spacing: 6) {
                Text(m.isPlaying ? m.title : "Kein Titel")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                Text(m.isPlaying ? m.artist : "Starte Apple Music oder Spotify")
                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
                if !m.app.isEmpty {
                    Text("via \(m.app)").font(.caption2).foregroundStyle(.white.opacity(0.25))
                }
            }

            HStack(spacing: 28) {
                MediaBtn(icon: "backward.fill") { m.previous() }
                MediaBtn(icon: m.isPlaying ? "pause.fill" : "play.fill", size: 28) { m.playPause() }
                MediaBtn(icon: "forward.fill") { m.next() }
            }
            Spacer()
        }
        .padding()
    }
}

struct MediaBtn: View {
    let icon: String; var size: CGFloat = 20; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: size, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timer expanded

struct TimerExpandedView: View {
    @ObservedObject var m: TimerWidgetModel
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Circle progress
            ZStack {
                Circle().stroke(.white.opacity(0.07), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: m.progress)
                    .stroke(m.isRunning ? Color.orange : .white.opacity(0.3),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: m.progress)
                Text(m.formatted)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(width: 130, height: 130)

            // Mode picker
            HStack(spacing: 6) {
                ForEach(TimerWidgetModel.Mode.allCases, id: \.rawValue) { mode in
                    Button(mode.rawValue) { m.setMode(mode) }
                        .font(.system(size: 11, weight: m.mode == mode ? .semibold : .regular))
                        .foregroundStyle(m.mode == mode ? .orange : .white.opacity(0.35))
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(m.mode == mode ? .orange.opacity(0.15) : .clear)
                        .clipShape(Capsule())
                }
            }

            // Controls
            HStack(spacing: 20) {
                Button { m.reset() } label: {
                    Image(systemName: "arrow.counterclockwise").font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Button { m.toggle() } label: {
                    Image(systemName: m.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.orange)
                        .frame(width: 56, height: 56)
                        .background(.orange.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer().frame(width: 36)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - System expanded

struct SystemExpandedView: View {
    @ObservedObject var m: SystemWidgetModel
    var body: some View {
        VStack(spacing: 14) {
            SysStat(icon: "cpu", label: "CPU",
                    value: String(format: "%.1f%%", m.cpuPercent),
                    progress: m.cpuPercent / 100, color: .green)
            SysStat(icon: "memorychip", label: "RAM",
                    value: String(format: "%.1f / %.0f GB", m.ramUsedGB, m.ramTotalGB),
                    progress: m.ramTotalGB > 0 ? m.ramUsedGB / m.ramTotalGB : 0, color: .blue)
            if m.batteryPercent >= 0 {
                SysStat(icon: m.isCharging ? "bolt.fill" : "battery.100",
                        label: m.isCharging ? "Akku (lädt)" : "Akku",
                        value: "\(m.batteryPercent)%",
                        progress: Double(m.batteryPercent) / 100,
                        color: m.batteryPercent < 20 ? .red : .yellow)
            }
            Button("Aktualisieren") { m.refresh() }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.white.opacity(0.35))
                .padding(.top, 4)
        }
        .padding(16)
    }
}

struct SysStat: View {
    let icon: String; let label: String; let value: String
    let progress: Double; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: icon).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                Spacer()
                Text(value).font(.system(size: 12, design: .monospaced)).foregroundStyle(.white.opacity(0.7))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.07)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * min(progress, 1), height: 6)
                        .animation(.easeOut, value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Weather expanded

struct WeatherExpandedView: View {
    @ObservedObject var m: WeatherWidgetModel
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            if m.isLoading && m.temperature.isEmpty {
                ProgressView().tint(.cyan)
            } else {
                Image(systemName: m.icon)
                    .font(.system(size: 52)).foregroundStyle(.cyan.gradient)
                Text(m.temperature)
                    .font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(m.condition).font(.system(size: 15)).foregroundStyle(.white.opacity(0.6))
                if !m.city.isEmpty {
                    Label(m.city, systemImage: "location.fill")
                        .font(.caption).foregroundStyle(.white.opacity(0.4))
                }
                Button("Aktualisieren") { Task { await m.fetch() } }
                    .buttonStyle(.plain).font(.caption).foregroundStyle(.cyan.opacity(0.6))
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }
}
