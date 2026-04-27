import Foundation
import AppKit

final class MusicStore: ObservableObject {
    static let shared = MusicStore()

    @Published var isPlaying = false
    @Published var title     = ""
    @Published var artist    = ""
    @Published var player    = ""   // "Music" | "Spotify"

    var hasTrack: Bool { isPlaying && !title.isEmpty }

    private init() {
        listen("com.apple.Music.playerInfo",              player: "Music")
        listen("com.spotify.client.PlaybackStateChanged", player: "Spotify")
    }

    private func listen(_ name: String, player: String) {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(name),
            object: nil, queue: .main
        ) { [weak self] n in self?.handle(n.userInfo, player: player) }
    }

    private func handle(_ info: [AnyHashable: Any]?, player: String) {
        guard let info else { return }
        isPlaying = (info["Player State"] as? String) == "Playing"
        title     = info["Name"]   as? String ?? ""
        artist    = info["Artist"] as? String ?? ""
        if !title.isEmpty { self.player = player }
    }

    func togglePlayPause() { run("playpause") }
    func nextTrack()        { run("next track") }
    func previousTrack()    { run("previous track") }

    private func run(_ cmd: String) {
        guard !player.isEmpty else { return }
        let src = "tell application \"\(player)\" to \(cmd)"
        Task.detached(priority: .userInitiated) {
            NSAppleScript(source: src)?.executeAndReturnError(nil)
        }
    }
}
