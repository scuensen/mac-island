import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var islandPanel: IslandPanel?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBarIcon()
        islandPanel = IslandPanel()
        islandPanel?.show()
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Claude Island")

        let menu = NSMenu()
        menu.addItem(withTitle: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingView(
                rootView: SettingsView().environmentObject(SettingsStore.shared))
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            win.title = "Claude Island – Einstellungen"
            win.contentView = hosting
            win.center()
            settingsWindow = win
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
