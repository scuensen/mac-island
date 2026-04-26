import AppKit
import SwiftUI

@MainActor
final class IslandManager: ObservableObject {

    // Widget models
    let claude  = ClaudeWidgetModel()
    let music   = MusicWidgetModel()
    let timer   = TimerWidgetModel()
    let system  = SystemWidgetModel()
    let weather = WeatherWidgetModel()

    // Island state
    @Published var isExpanded    = false
    @Published var activeWidget: WidgetKind = .claude

    var onResize: ((NSSize) -> Void)?
    private var clickMonitor: Any?
    private var autoCollapseTask: Task<Void, Never>?

    static let collapsedSize = NSSize(width: 300, height: 44)
    static let expandedSize  = NSSize(width: 560, height: 440)

    enum WidgetKind: String, CaseIterable, Identifiable {
        case claude, music, timer, system, weather
        var id: String { rawValue }

        var label: String {
            switch self {
            case .claude:  return "Claude"
            case .music:   return "Musik"
            case .timer:   return "Timer"
            case .system:  return "System"
            case .weather: return "Wetter"
            }
        }
        var icon: String {
            switch self {
            case .claude:  return "brain"
            case .music:   return "music.note"
            case .timer:   return "timer"
            case .system:  return "cpu"
            case .weather: return "cloud.sun.fill"
            }
        }
        var color: Color {
            switch self {
            case .claude:  return .blue
            case .music:   return .pink
            case .timer:   return .orange
            case .system:  return .green
            case .weather: return .cyan
            }
        }
    }

    // Only enabled widgets
    var enabledWidgets: [WidgetKind] {
        WidgetKind.allCases.filter { SettingsStore.shared.isWidgetEnabled($0.rawValue) }
    }

    // Contextual widget for collapsed state
    var collapsedWidget: WidgetKind {
        let s = SettingsStore.shared
        if s.isWidgetEnabled(WidgetKind.timer.rawValue)  && timer.isRunning { return .timer }
        if s.isWidgetEnabled(WidgetKind.music.rawValue)  && music.isPlaying { return .music }
        // Fall back to first enabled widget
        return enabledWidgets.contains(activeWidget) ? activeWidget : (enabledWidgets.first ?? .claude)
    }

    func startAll() {
        music.startPolling()
        system.startPolling()
        weather.startPolling()
    }

    // MARK: - Island control

    func expand(to widget: WidgetKind? = nil) {
        if let w = widget { activeWidget = w }
        guard !isExpanded else { return }
        isExpanded = true
        onResize?(Self.expandedSize)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in self?.collapse() }
        }
    }

    func collapse() {
        guard isExpanded else { return }
        autoCollapseTask?.cancel()
        isExpanded = false
        onResize?(Self.collapsedSize)
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }

    func toggle() { isExpanded ? collapse() : expand() }

    func scheduleAutoCollapse(after seconds: Double) {
        autoCollapseTask?.cancel()
        autoCollapseTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { collapse() }
        }
    }
}
