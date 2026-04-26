import Foundation
import AppKit

@MainActor
final class MusicWidgetModel: ObservableObject {
    @Published var title  = ""
    @Published var artist = ""
    @Published var isPlaying = false
    @Published var app: String = "" // "Music" or "Spotify"

    private var timer: Foundation.Timer?

    func startPolling() {
        refresh()
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopPolling() { timer?.invalidate(); timer = nil }

    func refresh() {
        Task.detached {
            let result = await Self.fetchNowPlaying()
            await MainActor.run {
                self.title     = result.title
                self.artist    = result.artist
                self.isPlaying = result.playing
                self.app       = result.app
            }
        }
    }

    private static func fetchNowPlaying() async -> (title: String, artist: String, playing: Bool, app: String) {
        // Try Apple Music first, then Spotify
        let musicScript = """
        tell application "System Events"
            if exists process "Music" then
                tell application "Music"
                    if player state is playing then
                        return (name of current track) & "|||" & (artist of current track) & "|||Music"
                    end if
                end tell
            end if
            return ""
        end tell
        """
        if let r = runAppleScript(musicScript), !r.isEmpty {
            let parts = r.components(separatedBy: "|||")
            return (parts[safe: 0] ?? "", parts[safe: 1] ?? "", true, "Music")
        }

        let spotifyScript = """
        tell application "System Events"
            if exists process "Spotify" then
                tell application "Spotify"
                    if player state is playing then
                        return (name of current track) & "|||" & (artist of current track) & "|||Spotify"
                    end if
                end tell
            end if
            return ""
        end tell
        """
        if let r = runAppleScript(spotifyScript), !r.isEmpty {
            let parts = r.components(separatedBy: "|||")
            return (parts[safe: 0] ?? "", parts[safe: 1] ?? "", true, "Spotify")
        }

        return ("", "", false, "")
    }

    private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        return result?.stringValue
    }

    func playPause() { sendCommand("playpause") }
    func next()      { sendCommand("next track") }
    func previous()  { sendCommand("previous track") }

    private func sendCommand(_ cmd: String) {
        guard !app.isEmpty else { return }
        let source = "tell application \"\(app)\" to \(cmd)"
        Task.detached { Self.runAppleScript(source) }
        Task { try? await Task.sleep(for: .seconds(0.3)); refresh() }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
