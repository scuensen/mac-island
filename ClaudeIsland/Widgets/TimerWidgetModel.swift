import Foundation
import AppKit

@MainActor
final class TimerWidgetModel: ObservableObject {
    @Published var remaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var mode: Mode = .focus
    @Published var customMinutes: Double = 25

    enum Mode: String, CaseIterable {
        case focus  = "Fokus"
        case short  = "Kurze Pause"
        case long   = "Lange Pause"
        case custom = "Eigene Zeit"

        var defaultSeconds: TimeInterval {
            switch self {
            case .focus:  return 25 * 60
            case .short:  return  5 * 60
            case .long:   return 15 * 60
            case .custom: return 25 * 60
            }
        }
    }

    private var ticker: Foundation.Timer?

    var formatted: String {
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var progress: Double {
        let total = mode == .custom ? customMinutes * 60 : mode.defaultSeconds
        return total > 0 ? 1 - remaining / total : 0
    }

    func setMode(_ m: Mode) {
        mode = m
        reset()
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        isRunning = true
        ticker = Foundation.Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    self.finish()
                }
            }
        }
    }

    func pause() {
        isRunning = false
        ticker?.invalidate(); ticker = nil
    }

    func reset() {
        pause()
        remaining = mode == .custom ? customMinutes * 60 : mode.defaultSeconds
    }

    private func finish() {
        pause()
        NSSound.beep()
        let n = NSUserNotification()
        n.title = "Mac Island — Timer fertig"
        n.informativeText = "\(mode.rawValue) abgeschlossen!"
        NSUserNotificationCenter.default.deliver(n)
        remaining = 0
    }
}
