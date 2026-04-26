import SwiftUI

struct IslandView: View {
    @ObservedObject var viewModel: ClaudeViewModel
    @StateObject private var usage = UsageStore.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(.black)
                .shadow(color: .black.opacity(0.55), radius: 14, y: 7)

            if viewModel.isExpanded {
                ExpandedView(viewModel: viewModel, usage: usage)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                CollapsedView(viewModel: viewModel, usage: usage)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: viewModel.isExpanded)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Collapsed

struct CollapsedView: View {
    @ObservedObject var viewModel: ClaudeViewModel
    @ObservedObject var usage: UsageStore

    var body: some View {
        HStack(spacing: 8) {
            BrainIcon(phase: viewModel.phase)

            Text("Claude")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            // Usage or phase indicator
            if SettingsStore.shared.showUsageInIsland && usage.sessionTotal > 0 {
                Text("\(usage.sessionTotal) tok")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }

            switch viewModel.phase {
            case .thinking:
                ProgressView().scaleEffect(0.65).tint(.blue)
            case .done:
                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.green)
            case .error:
                Image(systemName: "exclamationmark").font(.caption.bold()).foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.expand() }
    }
}

// MARK: - Expanded

struct ExpandedView: View {
    @ObservedObject var viewModel: ClaudeViewModel
    @ObservedObject var usage: UsageStore
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                BrainIcon(phase: viewModel.phase)
                Text("Claude")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if viewModel.phase == .thinking {
                    Text("Denkt…").font(.caption2).foregroundStyle(.blue)
                }
                Button { viewModel.collapse() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Rate limit bar (wenn verfügbar)
            if let pct = usage.rateLimit.tokensPercent {
                RateLimitBar(label: "Token-Limit", percent: pct,
                             remaining: usage.rateLimit.tokensRemaining,
                             limit: usage.rateLimit.tokensLimit,
                             reset: usage.rateLimit.tokensReset)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }

            Divider().background(.white.opacity(0.08))

            // Chat
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if viewModel.messages.isEmpty {
                            Text("Stell Claude eine Frage…")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 16)
                        }
                        ForEach(Array(viewModel.messages.enumerated()), id: \.offset) { i, m in
                            ChatBubble(query: m.q, response: m.r, tokens: m.tokens).id(i)
                        }
                        if viewModel.phase == .thinking { ThinkingRow() }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: .infinity)
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation { proxy.scrollTo(viewModel.messages.count - 1) }
                }
            }

            // Usage footer
            if SettingsStore.shared.showUsageInIsland {
                Divider().background(.white.opacity(0.08))
                HStack(spacing: 12) {
                    UsagePill(label: "Session", value: "\(usage.sessionTotal) tok")
                    UsagePill(label: "Heute", value: "\(usage.todayTokens) tok")
                    UsagePill(label: "Anfragen", value: "\(usage.sessionRequests)")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Divider().background(.white.opacity(0.08))

            // Input
            HStack(spacing: 8) {
                TextField("Frage eingeben…", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .focused($focused)
                    .onSubmit { viewModel.ask() }

                Button(action: viewModel.ask) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.query.isEmpty ? .white.opacity(0.2) : .blue)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.query.isEmpty || viewModel.phase == .thinking)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .onAppear { focused = true }
    }
}

// MARK: - Subviews

struct BrainIcon: View {
    let phase: IslandPhase
    var body: some View {
        Image(systemName: "brain")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(phase == .thinking ? .blue : .white.opacity(0.8))
            .symbolEffect(.pulse, isActive: phase == .thinking)
    }
}

struct RateLimitBar: View {
    let label: String
    let percent: Double
    let remaining: Int?
    let limit: Int?
    let reset: String?

    var color: Color { percent > 0.3 ? .green : percent > 0.1 ? .yellow : .red }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                if let rem = remaining, let lim = limit {
                    Text("\(rem) / \(lim)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(color.opacity(0.8))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.08)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: geo.size.width * percent, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct UsagePill: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

struct ChatBubble: View {
    let query: String
    let response: String
    let tokens: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer(minLength: 40)
                Text(query)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.blue.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "brain").font(.caption2).foregroundStyle(.blue).padding(.top, 3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(response)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                    if tokens > 0 {
                        Text("\(tokens) Tokens")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.leading, 4)
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
