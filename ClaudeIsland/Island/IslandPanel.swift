import AppKit
import SwiftUI

final class IslandPanel: NSPanel {
    private let viewModel = ClaudeViewModel()

    init() {
        let size = ClaudeViewModel.collapsedSize
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configure()
        placeAtTop()
        mountContent()
    }

    private func configure() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
    }

    private func placeAtTop(size: NSSize? = nil) {
        guard let screen = NSScreen.main else { return }
        let s = size ?? frame.size
        let x = screen.frame.midX - s.width / 2
        let y = screen.frame.maxY - s.height
        setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: false)
    }

    private func mountContent() {
        viewModel.onResize = { [weak self] newSize in
            self?.animateTo(size: newSize)
        }
        let root = IslandView(viewModel: viewModel)
        contentView = NSHostingView(rootView: root)
    }

    private func animateTo(size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let x = screen.frame.midX - size.width / 2
        let y = screen.frame.maxY - size.height
        let target = NSRect(x: x, y: y, width: size.width, height: size.height)
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.32
            $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(target, display: true, animate: true)
        }
    }

    func show() { orderFrontRegardless() }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
