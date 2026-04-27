import SwiftUI

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
    @StateObject private var usage = UsageStore.shared

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "brain")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(vm.phase == .thinking ? .blue : .white.opacity(0.85))
                .symbolEffect(.pulse, isActive: vm.phase == .thinking)

            Text("Claude")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            switch vm.phase {
            case .thinking:
                ProgressView().scaleEffect(0.65).tint(.blue)
            case .done:
                if let last = vm.messages.last {
                    Text(last.r)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .frame(maxWidth: 140, alignment: .trailing)
                }
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red).font(.caption)
            case .idle:
                if let rem = usage.rateLimit.tokensRemaining,
                   let lim = usage.rateLimit.tokensLimit, lim > 0 {
                    let pct = Double(rem) / Double(lim)
                    Text("\(rem / 1000)k / \(lim / 1000)k tok")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(
                            pct > 0.5 ? .green.opacity(0.65)
                            : pct > 0.2 ? .orange.opacity(0.7)
                            : .red.opacity(0.8))
                } else {
                    Text("Ready")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { vm.expand() }
    }
}

// MARK: - Expanded

struct ExpandedView: View {
    @ObservedObject var vm: ClaudeViewModel
    @StateObject private var usage = UsageStore.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: vm.phase == .thinking)
                Text("Claude")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                if vm.phase == .thinking {
                    Text("Denkt…").font(.caption2).foregroundStyle(.blue)
                }
                Spacer()
                if usage.sessionTotal > 0 && SettingsStore.shared.showUsageInIsland {
                    Text("\(usage.sessionTotal) tok")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                }
                Button { vm.collapse() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 10)

            Divider().background(.white.opacity(0.07))

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if vm.messages.isEmpty {
                            Text("Stell Claude eine Frage…")
                                .font(.caption).foregroundStyle(.white.opacity(0.25))
                                .frame(maxWidth: .infinity).padding(.top, 20)
                        }
                        ForEach(Array(vm.messages.enumerated()), id: \.offset) { i, m in
                            Bubble(query: m.q, response: m.r, tokens: m.tokens).id(i)
                        }
                        if vm.phase == .thinking { ThinkingBubble() }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation { proxy.scrollTo(vm.messages.count - 1) }
                }
            }

            Divider().background(.white.opacity(0.07))

            // Input
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
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .onAppear { focused = true }
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
