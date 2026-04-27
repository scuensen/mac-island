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
    }

    func show() { orderFrontRegardless() }

    private func place(size: NSSize? = nil) {
        guard let screen = NSScreen.main else { return }
        let s = size ?? frame.size
        setFrame(NSRect(x: screen.frame.midX - s.width / 2,
                        y: screen.frame.maxY - s.height,
                        width: s.width, height: s.height), display: false)
    }

    private func animateTo(_ size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let target = NSRect(x: screen.frame.midX - size.width / 2,
                            y: screen.frame.maxY - size.height,
                            width: size.width, height: size.height)
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.3
            $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(target, display: true, animate: true)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
