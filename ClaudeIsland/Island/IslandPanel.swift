import AppKit
import SwiftUI

final class IslandPanel: NSPanel {
    private let vm = ClaudeViewModel()

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: ClaudeViewModel.collapsed),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        backgroundColor = .clear; isOpaque = false; hasShadow = true
        isFloatingPanel = true; hidesOnDeactivate = false
        vm.onResize = { [weak self] size in self?.animateTo(size) }
        contentView = NSHostingView(rootView: IslandView(vm: vm))
        place()

        // Neu positionieren wenn sich Screens ändern
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in self?.place() }

    }

    func show() { orderFrontRegardless() }

    // Screen mit der Menüleiste — immer screens.first, NICHT .main
    private var menuBarScreen: NSScreen {
        NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
    }

    // Exakte Notch-Höhe live vom Screen lesen (kein Cache, kein Hardcode).
    // safeAreaInsets.top ist die präziseste Quelle; Fallback: Menüleisten-Fläche.
    private func notchHeight(for screen: NSScreen) -> CGFloat {
        let safe = screen.safeAreaInsets.top
        if safe > 5 { return safe }
        let menuArea = screen.frame.maxY - screen.visibleFrame.maxY
        return max(menuArea, NSStatusBar.system.thickness)
    }

    private func place(size: NSSize? = nil) {
        let screen = menuBarScreen
        let s = size ?? frame.size
        let x = screen.frame.midX - s.width / 2

        if s.height < 100 {
            // Für collapsed: Höhe live berechnen, Panel 22pt über Bildschirmrand
            // schieben damit gerundete obere Ecken abgeschnitten werden.
            let nH = notchHeight(for: screen)
            let totalH = nH + 22
            let y = screen.frame.maxY - nH   // sichtbares Unterende = Notch-Unterkante
            setFrame(NSRect(x: x, y: y, width: s.width, height: totalH), display: true)
            return
        }

        let y = screen.frame.maxY - s.height
        setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
    }

    private func animateTo(_ size: NSSize) {
        let screen = menuBarScreen

        if size.height < 100 {
            let nH = notchHeight(for: screen)
            let totalH = nH + 22
            let target = NSRect(
                x: screen.frame.midX - size.width / 2,
                y: screen.frame.maxY - nH,
                width: size.width, height: totalH)
            NSAnimationContext.runAnimationGroup {
                $0.duration = 0.3
                $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                animator().setFrame(target, display: true, animate: true)
            }
            return
        }

        let target = NSRect(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height,
            width: size.width, height: size.height)
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.3
            $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(target, display: true, animate: true)
        }
    }

    // macOS schiebt Fenster automatisch in den sichtbaren Bereich.
    // Überschreiben damit das Panel 22pt über den Bildschirmrand ragen kann
    // (die gerundeten oberen Ecken werden so vom Bildschirmrand abgeschnitten).
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
