import SwiftUI

// MARK: - Root

struct IslandView: View {
    @ObservedObject var vm: ClaudeViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(.black)
                .shadow(color: .black.opacity(0.6), radius: 16, y: 8)
            if vm.isExpanded {
                ExpandedView(vm: vm)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                CollapsedView(vm: vm)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: vm.isExpanded)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Collapsed

struct CollapsedView: View {
    @ObservedObject var vm: ClaudeViewModel
    @StateObject private var music = MusicStore.shared
    @StateObject private var usage = UsageStore.shared

    var body: some View {
        HStack(spacing: 6) {
            // Left: music wenn läuft, sonst Claude-Icon
            if music.hasTrack {
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.green.opacity(0.85))
                    Text(music.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !music.artist.isEmpty {
                        Text("· \(music.artist)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.38))
                            .lineLimit(1)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(vm.phase == .thinking ? .blue : .white.opacity(0.7))
                        .symbolEffect(.pulse, isActive: vm.phase == .thinking)
                    Text("Mac Island")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer(minLength: 0)

            // Right: Status / Claude-Verbrauch
            switch vm.phase {
            case .thinking:
                ProgressView().scaleEffect(0.6).tint(.blue)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red).font(.system(size: 10))
            case .done:
                if let last = vm.messages.last {
                    Text(last.r)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.38))
                        .lineLimit(1)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
            case .idle:
                if usage.todayTokens > 0 {
                    Text(fmtTok(usage.todayTokens))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { vm.expand() }
    }

    private func fmtTok(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

// MARK: - Expanded

enum IslandTab { case music, claude }

struct ExpandedView: View {
    @ObservedObject var vm: ClaudeViewModel
    @StateObject private var usage = UsageStore.shared
    @State private var tab: IslandTab = .claude

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 4) {
                tabBtn(.music,  icon: "music.note", label: "Musik")
                tabBtn(.claude, icon: "brain",      label: "Claude")
                Spacer()
                if usage.sessionTotal > 0 {
                    Text(fmtTok(usage.sessionTotal))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.2))
                }
                Button { vm.collapse() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.28))
                        .font(.system(size: 15))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 8)

            Divider().background(.white.opacity(0.07))

            if tab == .music {
                MusicWidgetView()
            } else {
                ClaudeWidgetView(vm: vm)
            }
        }
    }

    @ViewBuilder
    private func tabBtn(_ t: IslandTab, icon: String, label: String) -> some View {
        Button { withAnimation(.spring(response: 0.22)) { tab = t } } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(tab == t ? .white : .white.opacity(0.3))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(tab == t ? .white.opacity(0.09) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func fmtTok(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk tok", Double(n) / 1000) : "\(n) tok"
    }
}

// MARK: - Music Widget

struct MusicWidgetView: View {
    @StateObject private var music = MusicStore.shared

    var body: some View {
        if music.hasTrack {
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.07))
                        .frame(width: 110, height: 110)
                    Image(systemName: "music.note")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.22))
                }
                .padding(.bottom, 14)

                VStack(spacing: 4) {
                    Text(music.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(music.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.44))
                        .lineLimit(1)
                }
                .padding(.bottom, 22)

                HStack(spacing: 38) {
                    mediaBtn("backward.fill",  size: 20) { music.previousTrack() }
                    mediaBtn(music.isPlaying ? "pause.circle.fill" : "play.circle.fill", size: 44) {
                        music.togglePlayPause()
                    }
                    mediaBtn("forward.fill", size: 20) { music.nextTrack() }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.18))
                Text("Kein Titel läuft")
                    .font(.caption).foregroundStyle(.white.opacity(0.25))
                Text("Öffne Apple Music oder Spotify")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.14))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func mediaBtn(_ icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(.white.opacity(size > 30 ? 1.0 : 0.72))
        }.buttonStyle(.plain)
    }
}

// MARK: - Claude Widget

struct ClaudeWidgetView: View {
    @ObservedObject var vm: ClaudeViewModel
    @StateObject private var usage = UsageStore.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Verbrauch-Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Heute verbraucht")
                        .font(.system(size: 9)).foregroundStyle(.white.opacity(0.28))
                    Text(fmtTok(usage.todayTokens))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                if let rem = usage.rateLimit.tokensRemaining,
                   let lim = usage.rateLimit.tokensLimit, lim > 0 {
                    let pct = Double(rem) / Double(lim)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Limit verbleibend")
                            .font(.system(size: 9)).foregroundStyle(.white.opacity(0.28))
                        Text("\(fmtTok(rem)) / \(fmtTok(lim))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(pct > 0.5 ? .green.opacity(0.8) : pct > 0.2 ? .orange : .red)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Divider().background(.white.opacity(0.05))

            // Nachrichten
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if vm.messages.isEmpty {
                            Text("Stell Claude eine Frage…")
                                .font(.caption).foregroundStyle(.white.opacity(0.25))
                                .frame(maxWidth: .infinity).padding(.top, 16)
                        }
                        ForEach(Array(vm.messages.enumerated()), id: \.offset) { i, m in
                            Bubble(query: m.q, response: m.r, tokens: m.tokens).id(i)
                        }
                        if vm.phase == .thinking { ThinkingBubble() }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation { proxy.scrollTo(vm.messages.count - 1) }
                }
            }

            Divider().background(.white.opacity(0.07))

            // Eingabe
            HStack(spacing: 8) {
                TextField("Frage eingeben…", text: $vm.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13)).foregroundStyle(.white)
                    .focused($focused).onSubmit { vm.send() }
                Button(action: vm.send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(vm.query.isEmpty ? .white.opacity(0.2) : .blue)
                }
                .buttonStyle(.plain).disabled(vm.query.isEmpty || vm.phase == .thinking)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .onAppear { focused = true }
    }

    private func fmtTok(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

// MARK: - Subviews

struct Bubble: View {
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(response).font(.caption).foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                    if tokens > 0 {
                        Text("\(tokens) Tokens").font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.2)).padding(.leading, 4)
                    }
                }
            }
        }
    }
}

struct ThinkingBubble: View {
    @State private var dots = ""
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 6) {
            ProgressView().scaleEffect(0.6).tint(.blue)
            Text("Denkt nach\(dots)").font(.caption).foregroundStyle(.white.opacity(0.35))
        }
        .onReceive(timer) { _ in dots = dots.count < 3 ? dots + "." : "" }
    }
}
