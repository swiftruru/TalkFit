import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioPlaybackController {
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var progressTask: Task<Void, Never>?

    private(set) var activeURL: URL?
    private(set) var isPlaying = false
    private(set) var progress = 0.0
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var failureMessage: String?

    func toggle(url: URL, isAvailable: Bool = true) {
        if activeURL == url, let player {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                progressTask?.cancel()
            } else {
                if player.duration > 0,
                   player.currentTime >= player.duration - 0.05 {
                    player.currentTime = 0
                    currentTime = 0
                    progress = 0
                }
                guard player.play() else {
                    failureMessage = "目前無法播放這段錄音。"
                    return
                }
                isPlaying = true
                failureMessage = nil
                startProgressUpdates()
            }
            return
        }

        stop()
        activeURL = url
        guard isAvailable, FileManager.default.fileExists(atPath: url.path) else {
            failureMessage = "找不到這段錄音。"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            guard player.play() else {
                failureMessage = "目前無法播放這段錄音。"
                return
            }
            self.player = player
            duration = player.duration
            isPlaying = true
            failureMessage = nil
            startProgressUpdates()
        } catch {
            isPlaying = false
            failureMessage = "目前無法播放這段錄音。"
        }
    }

    func stop() {
        progressTask?.cancel()
        progressTask = nil
        player?.stop()
        player = nil
        activeURL = nil
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        failureMessage = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func startProgressUpdates() {
        progressTask?.cancel()
        progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                self.progress = player.duration > 0
                    ? player.currentTime / player.duration
                    : 0
                if !player.isPlaying {
                    self.isPlaying = false
                    self.currentTime = player.duration
                    self.progress = 1
                    self.progressTask = nil
                    return
                }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }
}
